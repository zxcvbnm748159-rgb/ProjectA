extends Node3D

const ENEMY_SCENE = preload("res://enemy.tscn")

@export var arena_half: float = 14.0
@export var min_spawn_dist: float = 8.0      # เพิ่มระยะห่างขั้นต่ำจากตัวผู้เล่นเพื่อป้องกันเกิดบนหัว
@export var max_spawn_dist: float = 13.0     # ระยะห่างสูงสุดจากตัวผู้เล่น
@export var spawn_interval: float = 0.8
@export var wave_delay: float = 10.0

var wave: int = 0
var to_spawn: int = 0
var spawn_timer: float = 0.0
var break_timer: float = 2.0
var player: Node3D


func _ready():
	add_to_group("spawner")
	
	# รอให้ Node เข้าสู่ Scene Tree สมบูรณ์ก่อน
	if not is_inside_tree():
		await tree_entered
		
	await get_tree().process_frame
	
	# เช็กว่า get_tree() ไม่เป็น null ก่อนเรียกใช้
	if get_tree():
		player = get_tree().get_first_node_in_group("player")


func _process(delta):
	# ถ้า player หลุด ให้พยายามดึง node player กลับมาใหม่
	if player == null and get_tree():
		player = get_tree().get_first_node_in_group("player")
		
	if player == null:
		return

	if to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = spawn_interval
			to_spawn -= 1
			spawn_enemy()
		return

	if get_tree() and get_tree().get_nodes_in_group("enemies").size() > 0:
		return

	break_timer -= delta
	if break_timer <= 0.0:
		start_next_wave()


# ฟังก์ชันสุ่มหาตำแหน่งเกิดที่ปลอดภัย ไม่ติดตัวผู้เล่น และไม่เกิดทับศัตรูตัวอื่น
func get_valid_spawn_position(is_boss: bool = false) -> Vector3:
	var best_pos: Vector3 = player.global_position
	
	# เพิ่มระยะห่างให้บอสเป็นพิเศษเพื่อป้องกันขนาดตัวใหญ่ทับผู้เล่น
	var effective_min_dist: float = min_spawn_dist + (3.0 if is_boss else 0.0)
	var effective_max_dist: float = max_spawn_dist + (3.0 if is_boss else 0.0)

	for attempt in 30:
		var angle: float = randf() * TAU
		var dist: float = randf_range(effective_min_dist, effective_max_dist)
		
		# สุ่มตำแหน่งทรงกลม/วงกลมรอบตัวผู้เล่น
		var candidate_pos: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * dist
		
		# หนีบไม่ให้ออกนอกขอบสนาม (เว้นระยะปลอดภัยจากขอบสนาม 2.0 หน่วย)
		candidate_pos.x = clampf(candidate_pos.x, -arena_half + 2.0, arena_half - 2.0)
		candidate_pos.z = clampf(candidate_pos.z, -arena_half + 2.0, arena_half - 2.0)
		candidate_pos.y = 1.0

		# 1. เช็กระยะห่างจากตัวผู้เล่นให้อยู่ในระยะปลอดภัย
		if candidate_pos.distance_to(player.global_position) < effective_min_dist * 0.8:
			continue

		# 2. เช็กว่าไม่ไปสปอว์นทับใกล้ศัตรูตัวอื่นที่มีอยู่แล้ว
		var too_close: bool = false
		for other in get_tree().get_nodes_in_group("enemies"):
			var min_gap: float = 4.0 if is_boss else 2.5
			if candidate_pos.distance_to(other.global_position) < min_gap:
				too_close = true
				break
		
		if not too_close:
			return candidate_pos
			
		best_pos = candidate_pos

	return best_pos


func spawn_enemy():
	# 1. เช็กว่าใช่ Wave บอสหรือไม่ (หาร 5 ลงตัว) และเป็นตัวสุดท้ายที่จะเสกใน Wave นั้นไหม
	var is_boss_wave: bool = (wave % 5 == 0) and (to_spawn == 0)
	
	# 2. ค้นหาตำแหน่งสปอว์นที่ปลอดภัย (ถ้าเป็นบอส จะขยับวงสปอว์นกว้างขึ้นกันทับตัว)
	var spawn_pos: Vector3 = get_valid_spawn_position(is_boss_wave)

	var e = ENEMY_SCENE.instantiate()
	var wave_mult: float = 1.0 + (wave - 1) * 0.2
	
	# 3. กำหนดค่าพลังและขนาดตัว
	if is_boss_wave:
		e.scale = Vector3(2.5, 2.5, 2.5) # ขยายขนาดโมเดลบอสให้ใหญ่ขึ้น 2.5 เท่า
		e.max_health = int((150 + wave * 30) * wave_mult) # เลือดเยอะกว่าปกติ
		e.attack_damage = int((15 + wave * 2) * wave_mult) # ดาเมจแรงขึ้น
		e.exp_reward = int(100 * wave_mult) # ให้ EXP เยอะ
		print("👹 บอสออกแล้วใน Wave %d!" % wave)
	else:
		# ค่าพลังศัตรูปกติ
		e.max_health = int((30 + (wave - 1) * 8) * wave_mult)
		e.attack_damage = int((5 + int((wave - 1) * 0.5)) * wave_mult)
		e.exp_reward = int((10 + (wave - 1) * 2) * wave_mult)
		
	e.speed = 3.0 + minf(wave * 0.15, 1.5)
	
	get_parent().add_child(e)
	EnemyAllocator.allocate(e, wave)
	e.global_position = spawn_pos


func get_status_text() -> String:
	var alive: int = get_tree().get_nodes_in_group("enemies").size()
	if wave == 0:
		return "เตรียมตัว..."
	if to_spawn > 0 or alive > 0:
		return "ระลอกที่ %d  |  ศัตรูเหลือ %d" % [wave, alive + to_spawn]
	return "ระลอกที่ %d เสร็จสิ้น!  ระลอกต่อไปใน %d วิ" % [wave, int(ceil(maxf(break_timer, 0.0)))]


func start_next_wave():
	wave += 1
	print("🌊 เริ่ม Wave: ", wave)
	
	# 1. รีเซ็ตเวลานับถอยหลังพักระหว่าง Wave ไม่ให้ลูปทำงานค้าง
	break_timer = wave_delay
	
	# 2. กำหนดจำนวนศัตรูที่จะสร้างใน Wave นี้ (เช่น เริ่มที่ 5 ตัว และเพิ่มขึ้นตาม Wave)
	to_spawn = 5 + (wave - 1) * 3
	spawn_timer = 0.0  # สั่งให้เสกตัวแรกทันที
	
	# 3. สั่ง Auto Save เมื่อเริ่ม Wave ใหม่
	var p = get_tree().get_first_node_in_group("player")
	if p:
		SaveSystem.save_game(wave, p)


func get_save_wave() -> int:
	var in_progress: bool = to_spawn > 0 or get_tree().get_nodes_in_group("enemies").size() > 0
	if in_progress:
		return maxi(wave - 1, 0)
	return wave
