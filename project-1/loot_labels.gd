extends Control

var labels := {}   # เก็บคู่ "ของบนพื้น" -> "ปุ่มป้ายชื่อ"
var player


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _process(_delta):
	if player == null:
		return
	var sv: SubViewport = player.get_viewport()
	var cam := sv.get_camera_3d()
	if cam == null:
		return
	var ratio := get_viewport().get_visible_rect().size / Vector2(sv.size)

	# ลบป้ายของที่หายไปแล้ว
	for loot in labels.keys():
		if not is_instance_valid(loot) or loot.is_queued_for_deletion():
			labels[loot].queue_free()
			labels.erase(loot)

	# สร้างป้ายใหม่ และคำนวณตำแหน่งบนจอ
	var placed: Array[Button] = []
	var loots := get_tree().get_nodes_in_group("loot")
	# เรียงตามตำแหน่งบนจอจากล่างขึ้นบน จะได้ดันซ้อนกันเป็นลำดับคงที่
	loots.sort_custom(func(a, b):
		return a.get_instance_id() < b.get_instance_id())

	for loot in loots:
		if loot.is_queued_for_deletion():
			continue
		if not labels.has(loot):
			labels[loot] = _make_label(loot)
		var btn: Button = labels[loot]
		var above: Vector3 = loot.global_position + Vector3(0, 1.4, 0)
		var screen_pos := cam.unproject_position(above) * ratio
		btn.position = screen_pos - btn.size / 2.0

		# ถ้าทับกับป้ายที่วางไปแล้ว ให้ดันขึ้นไปข้างบนทีละชั้น
		var moved := true
		while moved:
			moved = false
			for other in placed:
				var r1 := Rect2(btn.position, btn.size)
				var r2 := Rect2(other.position, other.size)
				if r1.intersects(r2):
					btn.position.y = other.position.y - btn.size.y - 2.0
					moved = true
		placed.append(btn)


func _make_label(loot) -> Button:
	var btn := Button.new()
	btn.text = loot.item.item_name
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", loot.item.get_color())
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.75)
	normal.set_content_margin_all(4)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.25, 0.25, 0.9)
	hover.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	btn.pressed.connect(func(): player.pick_up(loot))
	add_child(btn)
	return btn
