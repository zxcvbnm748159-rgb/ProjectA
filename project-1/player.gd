extends CharacterBody3D

signal inventory_changed

const PROJECTILE_SCENE = preload("res://projectile.tscn")

# ข้อมูลสกิลทั้งหมด อยากเพิ่มสกิลใหม่ก็เพิ่มก้อนตรงนี้
const SKILLS := {
	"fireball": {
		"key": KEY_Q, "name": "ลูกไฟ",
		"cost": 12, "cooldown": 0.5, "damage_mult": 1.5,
		"speed": 14.0, "range": 16.0, "size": 0.5,
		"pierce": false, "color": Color(1.0, 0.5, 0.1),
	},
	"orb": {
		"key": KEY_W, "name": "ลูกพลังทะลุ",
		"cost": 25, "cooldown": 1.5, "damage_mult": 2.5,
		"speed": 8.0, "range": 20.0, "size": 0.9,
		"pierce": true, "color": Color(0.7, 0.3, 1.0),
	},
	"lightning": {
		"key": KEY_E, "name": "สายฟ้า",
		"cost": 20, "cooldown": 1.0, "damage_mult": 1.2,
		"speed": 0.0, "range": 12.0, "size": 0.0,
		"pierce": false, "color": Color(0.5, 0.8, 1.0),
		"is_aoe": true,   # ← สกิล AOE
	},
	"blizzard": {
		"key": KEY_R, "name": "ลูกน้ำแข็ง",
		"cost": 18, "cooldown": 0.8, "damage_mult": 1.3,
		"speed": 10.0, "range": 18.0, "size": 0.6,
		"pierce": false, "color": Color(0.3, 0.7, 1.0),
		"is_projectile": true,
	},
}

@export var speed := 6.0
@export var max_health := 100
@export var max_mana := 60.0
@export var mana_regen := 6.0   # มานาฟื้นต่อวินาที
@export var attack_range := 2.5
@export var attack_damage := 10
@export var attack_cooldown := 0.4
@export var pickup_range := 1.5

var health: int
var mana: float
var target_pos := Vector3.ZERO
var moving := false
var attack_timer := 0.0
var pickup_target: Node3D = null
var mouse_pos := Vector2.ZERO        # ตำแหน่งเมาส์ล่าสุด ใช้เล็งสกิล
var skill_timers := {}               # คูลดาวน์ที่เหลือของแต่ละสกิล

var base_speed: float
var base_max_health: int
var base_damage: int
var base_max_mana: float
var base_mana_regen: float
var skill_dmg_mult: float = 1.0   # ตัวคูณดาเมจสกิลจากของที่สวม
var cdr: float = 0.0              # สัดส่วนลดคูลดาวน์ (0.2 = ลด 20%)

var level: int = 1
var exp_points: int = 0
var exp_to_next: int = 50
var passive_points: int = 0
var unlocked_passives: Array[String] = ["start"]
@export var arena_limit: float = 30.0   # เกินระยะนี้จากกลางสนามถือว่าออกนอกแมพ
@export var respawn_point: Vector3 = Vector3(0, 1, 0)
var owned_gems: Dictionary = {"multi": 1, "pierce": 1, "power": 1, "quick": 1}
var skill_supports: Dictionary = {}   # เช่น {"fireball": ["multi", ""]}

var inventory: Array[ItemData] = []
var equipped := {}
var walk_time: float = 0.0

func _flash(on: bool):
	# ใน player ไม่มีการแสดง visual flash เหมือน enemy
	# ปล่อยว่างก็ได้ หรือเพิ่ม visual feedback
	pass


func _ready():
	base_speed = speed
	base_max_health = max_health
	base_damage = attack_damage
	base_max_mana = max_mana
	base_mana_regen = mana_regen
	health = max_health
	mana = max_mana
	mouse_pos = get_viewport().get_visible_rect().size / 2.0
	for id in SKILLS:
		skill_timers[id] = 0.0
		skill_supports[id] = ["", ""]
	add_to_group("player")
	passive_points = 10   # ลบทิ้งหลังทดสอบ
	var model = get_node_or_null("Model")
	if model:
		ModelUtil.pixelate(model)


func add_item(item: ItemData):
	inventory.append(item)
	print("เก็บของ: ", item.item_name)
	inventory_changed.emit()


func equip(item: ItemData):
	if not inventory.has(item):
		return
	inventory.erase(item)
	if equipped.has(item.slot):
		inventory.append(equipped[item.slot])
	equipped[item.slot] = item
	recalc_stats()
	inventory_changed.emit()


func unequip(slot: String):
	if not equipped.has(slot):
		return
	inventory.append(equipped[slot])
	equipped.erase(slot)
	recalc_stats()
	inventory_changed.emit()


func recalc_stats():
	var bonus := {
		"damage": 0, "max_health": 0, "speed_pct": 0,
		"max_mana": 0, "mana_regen": 0, "skill_dmg_pct": 0, "cdr_pct": 0,
	}
	for slot in equipped:
		var it: ItemData = equipped[slot]
		for key in it.stats:
			bonus[key] = bonus.get(key, 0) + it.stats[key]
	for pid in unlocked_passives:
		var pstats: Dictionary = PassiveData.NODES[pid]["stats"]
		for key in pstats:
			bonus[key] = bonus.get(key, 0) + pstats[key]
	attack_damage = base_damage + bonus["damage"]
	max_health = base_max_health + bonus["max_health"]
	speed = base_speed * (1.0 + bonus["speed_pct"] / 100.0)
	max_mana = base_max_mana + bonus["max_mana"]
	mana_regen = base_mana_regen + bonus["mana_regen"]
	skill_dmg_mult = 1.0 + bonus["skill_dmg_pct"] / 100.0
	cdr = minf(bonus["cdr_pct"] / 100.0, 0.6)   # ลดได้สูงสุด 60%
	health = mini(health, max_health)
	mana = minf(mana, max_mana)

func gain_exp(amount: int):
	exp_points += amount
	while exp_points >= exp_to_next:
		exp_points -= exp_to_next
		level_up()


func level_up():
	level += 1
	passive_points += 1
	exp_to_next = int(50 * pow(1.25, level - 1))
	# ค่าฐานเพิ่มตามเลเวล แล้วคำนวณรวมกับของที่สวมใหม่
	base_max_health += 10
	base_damage += 1
	base_max_mana += 4
	recalc_stats()
	health = max_health   # เลื่อนเลเวลแล้วเลือดและมานาเต็ม
	mana = max_mana
	print("เลเวลอัป! เลเวล ", level)
	inventory_changed.emit()
	

func can_unlock(id: String) -> bool:
	if unlocked_passives.has(id) or passive_points <= 0:
		return false
	# ต้องมีเพื่อนบ้านที่เปิดแล้วอย่างน้อยหนึ่งโหนด
	for link in PassiveData.NODES[id]["links"]:
		if unlocked_passives.has(link):
			return true
	return false


func unlock_passive(id: String):
	if not can_unlock(id):
		return
	unlocked_passives.append(id)
	passive_points -= 1
	recalc_stats()
	inventory_changed.emit()
	
func check_out_of_bounds():
	var p: Vector3 = global_position
	if p.y < -3.0 or absf(p.x) > arena_limit or absf(p.z) > arena_limit:
		global_position = respawn_point
		velocity = Vector3.ZERO
		moving = false
		pickup_target = null
		print("ตัวละครออกนอกแมพ วาปกลับกลางสนาม")
func add_gem(gem_id: String):
	owned_gems[gem_id] = owned_gems.get(gem_id, 0) + 1
	print("ได้ Support Gem: ", GemData.GEMS[gem_id]["name"])
	inventory_changed.emit()


func gem_total() -> int:
	var n: int = 0
	for k in owned_gems:
		n += owned_gems[k]
	return n


# จำนวน gem ชนิดนี้ที่ยังว่างให้ใช้ (ไม่นับช่องที่กำลังเลือกอยู่เอง)
func gem_available(gem_id: String, skill_id: String, slot: int) -> int:
	var used: int = 0
	for sid in skill_supports:
		var arr: Array = skill_supports[sid]
		for i in arr.size():
			if arr[i] == gem_id and not (sid == skill_id and i == slot):
				used += 1
	return owned_gems.get(gem_id, 0) - used


func set_support(skill_id: String, slot: int, gem_id: String):
	if gem_id != "" and gem_available(gem_id, skill_id, slot) <= 0:
		return
	skill_supports[skill_id][slot] = gem_id
	inventory_changed.emit()


func get_skill_ids() -> Array:
	return SKILLS.keys()


func get_skill_label(id: String) -> String:
	var s: Dictionary = SKILLS[id]
	return "[%s] %s" % [OS.get_keycode_string(s["key"]), s["name"]]

func _animate_model(model: Node3D, delta: float):
	if moving:
		var cycle: float = walk_time * 8.0
		# หมุนตัวซ้าย-ขวา (แกว่ง)
		model.rotation.z = sin(cycle) * 0.1
		# ยกตัวขึ้นลงเพิ่ม (ใช้ local position เท่านั้น)
		model.position.y = -0.5 + abs(sin(cycle * 0.5)) * 0.2
	else:
		# ยืนนิ่ง: กลับมาเดิม
		model.position.y = -0.5
		model.rotation.z = 0.0

func walk_to(pos: Vector3):
	target_pos = pos
	target_pos.x = clampf(target_pos.x, -28.0, 28.0)
	target_pos.z = clampf(target_pos.z, -28.0, 28.0)
	target_pos.y = global_position.y
	moving = true


func pick_up(loot: Node3D):
	pickup_target = loot
	walk_to(loot.global_position)


func get_aim_direction() -> Vector3:
	# แปลงตำแหน่งเมาส์เป็นทิศบนพื้น
	var forward := -global_transform.basis.z
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return forward
	var origin = cam.project_ray_origin(mouse_pos)
	var dir = cam.project_ray_normal(mouse_pos)
	var point = Plane(Vector3.UP, 0.0).intersects_ray(origin, dir)
	if point == null:
		return forward
	var d: Vector3 = point - global_position
	d.y = 0
	if d.length() < 0.1:
		return forward
	return d.normalized()


func cast_skill(id: String):
	var s: Dictionary = SKILLS[id]
	var sup: Dictionary = GemData.combine(skill_supports.get(id, []))
	var cost: float = s["cost"] * sup["mana"]
	if skill_timers[id] > 0.0:
		return
	if mana < cost:
		print("มานาไม่พอ")
		return
	mana -= cost
	skill_timers[id] = s["cooldown"] * sup["cd"] * (1.0 - cdr)

	var dir: Vector3 = get_aim_direction()
	look_at(global_position + dir, Vector3.UP)

	# ตรวจสอบว่าเป็นสกิล AOE หรือ projectile
	if s.get("is_aoe", false):
		# สกิล Lightning: โจมตีศัตรูทั้งหมดในวงกว้าง
		_cast_lightning_skill(s, sup)
	else:
		# สกิล projectile ปกติ (Fireball, Orb, Blizzard)
		_cast_projectile_skill(dir, s, sup)


func _cast_lightning_skill(s: Dictionary, sup: Dictionary):
	# สร้าง visual effect
	var effect = preload("res://lightning_effect.gd").new()
	effect.position = global_position
	effect.position.y = 0.5
	get_parent().add_child(effect)
	
	# Lightning: ตรวจสอบศัตรูทั้งหมดในระยะ
	var range_val: float = s["range"]
	var dmg: int = int(attack_damage * s["damage_mult"] * skill_dmg_mult * sup["dmg"])
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= range_val:
			enemy.take_damage(dmg)


func _cast_projectile_skill(dir: Vector3, s: Dictionary, sup: Dictionary):
	# ยิงหลายลูกเป็นรูปพัด กางลูกละ 12 องศา
	var count: int = 1 + int(sup["extra"])
	var spread: float = deg_to_rad(12.0)
	for i in count:
		var angle: float = (i - (count - 1) / 2.0) * spread
		var d: Vector3 = dir.rotated(Vector3.UP, angle)
		var p = PROJECTILE_SCENE.instantiate()
		p.direction = d
		p.speed = s["speed"]
		p.max_distance = s["range"]
		p.size = s["size"]
		p.pierce = s["pierce"] or sup["pierce"]
		p.color = s["color"]
		p.damage = int(attack_damage * s["damage_mult"] * skill_dmg_mult * sup["dmg"])
		get_parent().add_child(p)
		p.global_position = global_position + d * 0.8

func get_skill_text() -> String:
	var parts: PackedStringArray = []
	for id in SKILLS:
		var s: Dictionary = SKILLS[id]
		var sup: Dictionary = GemData.combine(skill_supports.get(id, []))
		var key_name: String = OS.get_keycode_string(s["key"])
		var cost: int = int(round(s["cost"] * sup["mana"]))
		var t: float = skill_timers[id]
		var state: String = "พร้อม" if t <= 0.0 else "%.1f วิ" % t
		parts.append("[%s] %s (%d มานา) %s" % [key_name, s["name"], cost, state])
	return "     ".join(parts)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	elif event is InputEventMouseButton and event.pressed:
		mouse_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cam = get_viewport().get_camera_3d()
			var origin = cam.project_ray_origin(event.position)
			var dir = cam.project_ray_normal(event.position)
			var point = Plane(Vector3.UP, 0.0).intersects_ray(origin, dir)
			if point != null:
				pickup_target = null
				walk_to(point)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			attack()
	elif event is InputEventKey and event.pressed and not event.echo:
		for id in SKILLS:
			if event.keycode == SKILLS[id]["key"]:
				cast_skill(id)


func attack():
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	moving = false
	pickup_target = null
	velocity = Vector3.ZERO
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= attack_range:
			enemy.take_damage(attack_damage)


func take_damage(amount: int):
	if health <= 0:
		return
	health -= amount
	_flash(true)
	
	if health <= 0:
		health = 0
		
		# บันทึก high score เมื่อตาย
		var spawner = get_tree().get_first_node_in_group("spawner")
		if spawner:
			var current_wave: int = spawner.wave
			var high_score: int = SaveSystem.load_high_score()
			if current_wave > high_score:
				SaveSystem.save_high_score(current_wave)
				print("🏆 High Score ใหม่! Wave %d" % current_wave)
		
		# ขึ้น Game Over Screen
		var game_over = preload("res://game_over_screen.tscn").instantiate()
		get_tree().root.add_child(game_over)
		
		# ปิดการควบคุม หยุดเวลา และซ่อนตัวละคร
		set_process_unhandled_input(false)
		set_physics_process(false)
		Engine.time_scale = 0.0
		hide()
		return
		
	await get_tree().create_timer(0.1).timeout
	_flash(false)


func _physics_process(delta):
	attack_timer -= delta

	# มานาฟื้นเรื่อย ๆ และคูลดาวน์นับถอยหลัง
	mana = minf(max_mana, mana + mana_regen * delta)
	for id in skill_timers:
		skill_timers[id] = maxf(0.0, skill_timers[id] - delta)

	# ← เพิ่ม walk_time ก่อน walk logic
	if moving:
		walk_time += delta
	else:
		walk_time = 0.0

	if pickup_target != null:
		if not is_instance_valid(pickup_target):
			pickup_target = null
		elif global_position.distance_to(pickup_target.global_position) <= pickup_range:
			add_item(pickup_target.item)
			pickup_target.queue_free()
			pickup_target = null
			moving = false
			velocity = Vector3.ZERO

	# Walk logic (มาหลัง walk_time)
	if moving:
		var direction = (target_pos - global_position).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		if global_position.distance_to(target_pos) < 1.5:
			moving = false
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# หมุนตัวหันไปทางเมาส์เสมอ
	var aim_dir: Vector3 = get_aim_direction()
	if aim_dir.length() > 0.1:
		look_at(global_position + aim_dir, Vector3.UP)

	var model = get_node_or_null("Model")
	if model:
		_animate_model(model, delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 20.0 * delta

	if global_position.y < -10.0:
		get_tree().reload_current_scene()

	move_and_slide()
	check_out_of_bounds()
