class_name SaveSystem
extends Node

const SAVE_PATH = "user://autosave.save"

# 1. ฟังก์ชันตรวจสอบไฟล์เซฟ
static func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# 2. ฟังก์ชันบันทึกเกม (รับค่า wave และ player)
# ปรับแต่งใน SaveSystem.save_game()
static func save_game(wave: int, player: Node) -> bool:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		return false

	# ดึงไอเทมในกระเป๋าผู้เล่น แปลงเก็บเป็น Array
	var inv_array = []
	if player and "inventory" in player:
		for item in player.inventory:
			# บันทึกเป็น ID หรือชื่อไอเทมไว้
			if item.has_method("to_dict"):
				inv_array.append(item.to_dict())
			elif "id" in item:
				inv_array.append(item.id)

	var save_data = {
		"wave": wave,
		"player_health": player.max_health if player else 100,
		"inventory": inv_array # เพิ่มบรรทัดนี้ลงในไฟล์เซฟ
	}

	save_file.store_line(JSON.stringify(save_data))
	save_file.close()
	print("💾 บันทึกเกมพร้อมไอเทมในกระเป๋าสำเร็จ!")
	return true


# 3. ฟังก์ชันโหลดเซฟเข้าสู่ Spawner
static func load_game(tree: SceneTree) -> bool:
	if not has_save_file():
		return false
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return false
		
	var json_string = save_file.get_line()
	save_file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var data = json.data
		var spawner = tree.get_first_node_in_group("spawner")
		if spawner and data.has("wave"):
			spawner.wave = data["wave"] - 1 # ลบ 1 ไว้เพื่อให้ spawner เริ่มรันเข้าสู่ wave ล่าสุดได้ถูกต้อง
		return true
		
	return false


# 4. ฟังก์ชันลบไฟล์เซฟ
static func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ ลบไฟล์เซฟเรียบร้อย")


# 5. ฟังก์ชัน High Score
static func load_high_score() -> int:
	if not has_save_file():
		return 1
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_line()
		save_file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			return json.data.get("wave", 1)
	return 1

static func load_save_data() -> Dictionary:
	if not has_save_file():
		return {}
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {}
		
	var json_string = save_file.get_line()
	save_file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return json.data
		
	return {}

# เพิ่มต่อท้ายในไฟล์ save_system.gd
static func save_high_score(wave: int) -> void:
	var data = {}
	if has_save_file():
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_line()
			save_file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				data = json.data

	# อัปเดต high_score เฉพาะเมื่อ wave ใหม่มากกว่าเดิม
	data["high_score"] = max(data.get("high_score", 1), wave)

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_line(JSON.stringify(data))
		save_file.close()
		print("🏆 บันทึก High Score เรียบร้อย: Wave %d" % data["high_score"])
