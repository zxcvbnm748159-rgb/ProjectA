extends CharacterBody3D
enum ENEMY_TYPE {BASIC, MINION, TANK, BOSS}

const LOOT_SCENE = preload("res://loot_drop.tscn")

@export var speed: float = 3.0
@export var max_health: int = 30
@export var attack_range: float = 1.6
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.0
@export var drop_chance: float = 1.0
@export var separation_radius: float = 1.3   # ใกล้กันกว่านี้จะเริ่มผลักกัน
@export var exp_reward: int = 10
var enemy_type: ENEMY_TYPE = ENEMY_TYPE.BASIC
@export var gem_drop_chance: float = 0.15

var health: int
var player: Node3D
var cooldown: float = 0.0
var boss_skill_cooldown: float = 0.0
var gravity: float = 20.0
var mat := StandardMaterial3D.new()
var model_meshes: Array[MeshInstance3D] = []
var flash_mat := StandardMaterial3D.new()

func set_type(type: ENEMY_TYPE):
	enemy_type = type
	match type:
		ENEMY_TYPE.MINION:
			max_health = 15
			health = 15
			attack_damage = 3
			speed = 5.0
			exp_reward = 5
		ENEMY_TYPE.TANK:
			max_health = 60
			health = 60
			attack_damage = 8
			speed = 1.5
			exp_reward = 25
		ENEMY_TYPE.BOSS:
			max_health = 100
			health = 100
			attack_damage = 10
			speed = 2.0
			exp_reward = 50
		_:   # BASIC
			max_health = 30
			health = 30
			attack_damage = 5
			speed = 3.0
			exp_reward = 10

func _ready():
	health = max_health
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	
	# ซ่อน mesh เดิม ถ้ามี
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").visible = false
	
	var model = get_node_or_null("Model")
	if model:
		ModelUtil.pixelate(model)
		model_meshes = ModelUtil.collect_meshes(model)
	flash_mat.albedo_color = Color(1, 1, 1, 0.65)
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _flash(on: bool):
	for m in model_meshes:
		if is_instance_valid(m):
			m.material_overlay = flash_mat if on else null

func _cast_boss_skill():
	# บอสยิง 3 ลูกกระสุนกลับไปที่ผู้เล่น
	if player == null or not is_instance_valid(player):
		return
	
	var dir_to_player: Vector3 = (player.global_position - global_position).normalized()
	
	# ยิง 3 ลูกเป็นพัด
	for i in 3:
		var angle: float = (i - 1.0) * deg_to_rad(15.0)   # 15° ห่างกัน
		var d: Vector3 = dir_to_player.rotated(Vector3.UP, angle)
		
		var projectile = preload("res://projectile.tscn").instantiate()
		projectile.direction = d
		projectile.speed = 12.0
		projectile.max_distance = 30.0
		projectile.size = 0.4
		projectile.pierce = false
		projectile.color = Color(1.0, 0.2, 0.2)   # สีแดง
		projectile.damage = attack_damage
		
		get_parent().add_child(projectile)
		projectile.global_position = global_position + d * 1.5
		

func take_damage(amount: int):
	if health <= 0:
		return
	health -= amount
	_flash(true)
	if health <= 0:
		drop_loot()
		if player and player.has_method("gain_exp"):
			player.gain_exp(exp_reward)
		if player and player.has_method("add_gem") and randf() < gem_drop_chance:
			player.add_gem(GemData.GEMS.keys().pick_random())
		queue_free()
		return
	await get_tree().create_timer(0.1).timeout
	_flash(false)


func drop_loot():
	if randf() > drop_chance:
		return
	var drop = LOOT_SCENE.instantiate()
	drop.item = ItemGenerator.roll()
	get_parent().add_child(drop)
	drop.global_position = Vector3(global_position.x, 0.3, global_position.z)


func get_separation() -> Vector3:
	# รวมแรงผลักจากศัตรูตัวอื่นที่อยู่ใกล้ ยิ่งใกล้ยิ่งผลักแรง
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var diff: Vector3 = global_position - other.global_position
		diff.y = 0
		var dist: float = diff.length()
		if dist > 0.001 and dist < separation_radius:
			push += diff.normalized() * (separation_radius - dist) / separation_radius
	return push


func _physics_process(delta):
	if global_position.y < -3.0:
		global_position = Vector3(0, 1, 0)
		velocity = Vector3.ZERO
	
	if player == null:
		return
	cooldown -= delta
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	var sep: Vector3 = get_separation()

	if to_player.length() > attack_range:
		# ยังไกล: เดินเข้าหาผู้เล่น แต่เบี่ยงออกจากเพื่อนด้วย
		var move_dir: Vector3 = (to_player.normalized() + sep * 1.5).normalized()
		velocity = move_dir * speed
		if move_dir.length() > 0.01:
			look_at(global_position + move_dir, Vector3.UP)
	else:
		# อยู่ในระยะ: ยืนตี แต่ยังขยับหลบเพื่อนเบา ๆ ให้ล้อมเป็นวง
		velocity = sep * speed * 0.5
		if cooldown <= 0.0:
			player.take_damage(attack_damage)
			cooldown = attack_cooldown
		
		# ← เพิ่มบอสสกิล
		if enemy_type == ENEMY_TYPE.BOSS:
			boss_skill_cooldown -= delta
			if boss_skill_cooldown <= 0.0:
				_cast_boss_skill()
				boss_skill_cooldown = 3.0   # ยิง 1 ครั้งทุก 3 วิ
	
	# ← เพิ่มส่วนนี้: บอสยิงตั้งแต่ไกล
	if enemy_type == ENEMY_TYPE.BOSS and to_player.length() > attack_range:
		boss_skill_cooldown -= delta
		if boss_skill_cooldown <= 0.0:
			_cast_boss_skill()
			boss_skill_cooldown = 3.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
