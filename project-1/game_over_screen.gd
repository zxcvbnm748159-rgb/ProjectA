extends CanvasLayer

# อ้างอิง Node ตามโครงสร้าง Hierarchy
@onready var wave_label: Label = $Panel/Container/WaveLabel
@onready var high_score_label: Label = $Panel/Container/HighScoreLabel
@onready var retry_button: Button = $Panel/Container/ButtonContainer/RetryButton
@onready var load_button: Button = $Panel/Container/ButtonContainer/LoadButton


func _ready():
	# 1. ตั้งค่า Process Mode ให้ทำงานตลอดเวลา (เพื่อให้คลิกปุ่มได้แม้อยู่ในช่วงหยุดเวลา)
	process_mode = PROCESS_MODE_ALWAYS
	
	# 2. เชื่อมต่อสัญญาณกดปุ่ม (Signals)
	retry_button.pressed.connect(_on_retry_pressed)
	load_button.pressed.connect(_on_load_pressed)
	
	# 3. ดึงค่า Wave และ High Score มาแสดงบน Label
	_update_labels_ui()
	
	# 4. เช็กว่ามีไฟล์เซฟหรือไม่
	if SaveSystem.has_save_file():
		load_button.disabled = false
	else:
		load_button.disabled = true
		load_button.tooltip_text = "ไม่พบไฟล์บันทึก"


# อัปเดตข้อความบน UI
func _update_labels_ui():
	var spawner = get_tree().get_first_node_in_group("spawner")
	var current_wave: int = spawner.wave if spawner else 1
	var high_score: int = SaveSystem.load_high_score()
	
	wave_label.text = "ระลอกที่เข้าถึง: %d" % current_wave
	high_score_label.text = "สถิติสูงสุด: Wave %d" % high_score


# ปุ่ม Retry: เริ่มเกมใหม่ที่ Wave 1
func _on_retry_pressed():
	Engine.time_scale = 1.0  # คืนค่าเวลาเกมให้เดินปกติ
	get_tree().reload_current_scene()


# ปุ่ม LoadButton: โหลดเซฟล่าสุดแล้วเริ่มเกมใหม่
func _on_load_pressed():
	Engine.time_scale = 1.0  # คืนค่าเวลาเกมให้เดินปกติ
	
	if SaveSystem.has_save_file():
		get_tree().reload_current_scene()
	else:
		get_tree().reload_current_scene()
