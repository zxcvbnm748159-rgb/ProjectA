extends CanvasLayer

func _ready():
	visible = false
	# สั่งให้เมนูนี้ยังคงทำงานได้ แม้เกมจะสั่งหยุด (Pause) อยู่
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# เขียนโค้ดดักจับการกดปุ่มโดยตรง (ไม่ต้องไปนั่งต่อ Signal ให้ยุ่งยาก)
	find_child("ResumeButton", true, false).pressed.connect(_on_resume_pressed)
	find_child("QuitButton", true, false).pressed.connect(_on_quit_pressed)


func _input(event):
	# กด Esc (ui_cancel) เพื่อ เปิด/ปิด พักเกม
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	visible = not visible
	get_tree().paused = visible


func _on_resume_pressed():
	toggle_pause()


func _on_quit_pressed():
	# 1. คืนค่าเวลาเกมให้เดินปกติ
	get_tree().paused = false
	
	# 2. ลบไฟล์เซฟเก่าทิ้ง เพื่อไม่ให้เกมโหลด Wave เดิมกลับมา
	SaveSystem.delete_save()
	
	# 3. สั่งรีโหลดฉากใหม่ (เกมจะเริ่มตั้งแต่ Wave 1 ใหม่ทันที)
	get_tree().reload_current_scene()
