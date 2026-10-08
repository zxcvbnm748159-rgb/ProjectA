extends Control

@onready var bar: ProgressBar = $CanvasLayer/HealthBar
@onready var mana_bar: ProgressBar = $CanvasLayer/ManaBar
@onready var exp_bar: ProgressBar = $CanvasLayer/ExpBar
@onready var level_label: Label = $CanvasLayer/LevelInfo
@onready var skill_label: Label = $CanvasLayer/SkillInfo
@onready var wave_label: Label = $CanvasLayer/WaveInfo

var toast: Label
var toast_time: float = 0.0


func _ready():
	_set_bar_color(bar, Color(0.8, 0.15, 0.15))
	_set_bar_color(mana_bar, Color(0.2, 0.4, 1.0))
	_set_bar_color(exp_bar, Color(0.95, 0.8, 0.2))
	wave_label.add_theme_font_size_override("font_size", 22)

	# ข้อความแจ้งสถานะกลางล่างจอ
	toast = Label.new()
	toast.position = Vector2(430, 560)
	toast.add_theme_font_size_override("font_size", 20)
	toast.modulate.a = 0.0
	$CanvasLayer.add_child(toast)

	# รอให้ทุกอย่างพร้อมก่อน แล้วโหลดเซฟ (ถ้ามี)
	await get_tree().process_frame
	await get_tree().process_frame
	if SaveSystem.has_save_file():
		if SaveSystem.load_game(get_tree()):
			show_toast("โหลดเซฟแล้ว")
		else:
			show_toast("อ่านไฟล์เซฟไม่ได้ เริ่มเกมใหม่")


func _set_bar_color(pb: ProgressBar, color: Color):
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	pb.add_theme_stylebox_override("fill", fill)


func show_toast(text: String):
	toast.text = text
	toast_time = 2.0


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			var spawner = get_tree().get_first_node_in_group("spawner")
			var player = get_tree().get_first_node_in_group("player")
			var current_wave = spawner.wave if spawner else 1
			
			if SaveSystem.save_game(current_wave, player):
				show_toast("บันทึกเกมแล้ว")
				
		elif event.keycode == KEY_L:
			get_tree().reload_current_scene()   # ฉากเริ่มใหม่แล้วโหลดเซฟเองตอน _ready
			
		elif event.keycode == KEY_N and event.shift_pressed:
			SaveSystem.delete_save()
			show_toast("ลบไฟล์เซฟเรียบร้อย")
			get_tree().reload_current_scene()

func _process(delta):
	if toast_time > 0.0:
		toast_time -= delta
		toast.modulate.a = clampf(toast_time, 0.0, 1.0)

	var p = get_tree().get_first_node_in_group("player")
	if p:
		bar.max_value = p.max_health
		bar.value = p.health
		mana_bar.max_value = p.max_mana
		mana_bar.value = p.mana
		exp_bar.max_value = p.exp_to_next
		exp_bar.value = p.exp_points
		level_label.text = "เลเวล %d  |  แต้ม Passive: %d  |  Gem: %d (กด G)" % [
			p.level, p.passive_points, p.gem_total()]
		skill_label.text = p.get_skill_text()
	var sp = get_tree().get_first_node_in_group("spawner")
	if sp:
		wave_label.text = sp.get_status_text()
