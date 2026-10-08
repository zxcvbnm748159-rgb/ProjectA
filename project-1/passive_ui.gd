extends Panel

const NODE_SIZE := Vector2(64, 44)
const COLOR_LOCKED := Color(0.25, 0.25, 0.3)
const COLOR_AVAILABLE := Color(0.85, 0.65, 0.15)
const COLOR_UNLOCKED := Color(0.3, 0.75, 0.4)

var player
var buttons := {}
var title: Label
var info: Label
var lines: Control


func _ready():
	visible = false
	# ชั้นวาดเส้นเชื่อม (วางล่างสุด ให้ปุ่มทับ)
	lines = Control.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.draw.connect(_draw_lines)
	add_child(lines)

	title = Label.new()
	title.position = Vector2(12, 8)
	add_child(title)

	info = Label.new()
	info.position = Vector2(12, 462)
	info.text = "เลื่อนเมาส์ไปที่โหนดเพื่อดูโบนัส / คลิกเพื่อเปิด (ต้องติดกับโหนดสีเขียว)"
	add_child(info)

	for id in PassiveData.NODES:
		var d: Dictionary = PassiveData.NODES[id]
		var btn := Button.new()
		btn.text = d["name"]
		btn.size = NODE_SIZE
		btn.position = d["pos"] - NODE_SIZE / 2.0
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_pressed.bind(id))
		btn.mouse_entered.connect(_on_hover.bind(id))
		add_child(btn)
		buttons[id] = btn

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.inventory_changed.connect(refresh)


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_P:
		visible = not visible
		if visible:
			refresh()


func refresh():
	if player == null:
		return
	title.text = "Passive Tree   |   แต้มที่เหลือ: %d" % player.passive_points
	for id in buttons:
		var btn: Button = buttons[id]
		var color: Color
		if player.unlocked_passives.has(id):
			color = COLOR_UNLOCKED
		elif player.can_unlock(id):
			color = COLOR_AVAILABLE
		else:
			color = COLOR_LOCKED
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
	lines.queue_redraw()


func _draw_lines():
	for id in PassiveData.NODES:
		var a: Vector2 = PassiveData.NODES[id]["pos"]
		for link in PassiveData.NODES[id]["links"]:
			var b: Vector2 = PassiveData.NODES[link]["pos"]
			var on: bool = player != null and player.unlocked_passives.has(id) \
					and player.unlocked_passives.has(link)
			var c := COLOR_UNLOCKED if on else Color(0.4, 0.4, 0.45)
			lines.draw_line(a, b, c, 3.0 if on else 2.0)


func _on_hover(id: String):
	var d: Dictionary = PassiveData.NODES[id]
	info.text = "%s: %s" % [d["name"], PassiveData.describe(d["stats"]).replace("\n", ", ")]


func _on_pressed(id: String):
	if player:
		player.unlock_passive(id)
