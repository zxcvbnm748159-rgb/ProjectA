extends Panel

var player
var title: Label
var info: Label
var dropdowns := {}   # skill_id -> [OptionButton, OptionButton]
var summaries := {}   # skill_id -> Label


func _ready():
	visible = false
	title = Label.new()
	title.position = Vector2(12, 8)
	title.text = "Support Gem   |   เสียบได้สกิลละ 2 ช่อง (กด G เพื่อปิด)"
	add_child(title)

	info = Label.new()
	info.position = Vector2(12, size.y - 30)
	info.text = "เลือก gem จากรายการในแต่ละช่อง"
	add_child(info)

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var row: int = 0
	for skill_id in player.get_skill_ids():
		var y: float = 50.0 + row * 80.0
		var name_label := Label.new()
		name_label.text = player.get_skill_label(skill_id)
		name_label.position = Vector2(12, y + 4)
		add_child(name_label)

		var pair: Array = []
		for slot in 2:
			var ob := OptionButton.new()
			ob.position = Vector2(180 + slot * 210, y)
			ob.size = Vector2(200, 30)
			ob.focus_mode = Control.FOCUS_NONE
			ob.item_selected.connect(_on_pick.bind(skill_id, slot))
			add_child(ob)
			pair.append(ob)
		dropdowns[skill_id] = pair

		var sum := Label.new()
		sum.position = Vector2(12, y + 38)
		add_child(sum)
		summaries[skill_id] = sum
		row += 1

	player.inventory_changed.connect(func(): refresh.call_deferred())
	refresh()


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_G:
		visible = not visible
		if visible:
			refresh()


func refresh():
	if player == null:
		return
	for skill_id in dropdowns:
		var current: Array = player.skill_supports.get(skill_id, ["", ""])
		var pair: Array = dropdowns[skill_id]
		for slot in 2:
			var ob: OptionButton = pair[slot]
			ob.clear()
			ob.add_item("(ว่าง)")
			ob.set_item_metadata(0, "")
			var select_idx: int = 0
			for gem_id in GemData.GEMS:
				var left: int = player.gem_available(gem_id, skill_id, slot)
				var is_current: bool = current[slot] == gem_id
				if left <= 0 and not is_current:
					continue   # หมดแล้วและไม่ได้ใช้อยู่ ไม่ต้องโชว์
				var idx: int = ob.item_count
				ob.add_item("%s (เหลือ %d)" % [GemData.GEMS[gem_id]["name"], left])
				ob.set_item_metadata(idx, gem_id)
				if is_current:
					select_idx = idx
			ob.select(select_idx)
		summaries[skill_id].text = GemData.summarize(current)


func _on_pick(index: int, skill_id: String, slot: int):
	var ob: OptionButton = dropdowns[skill_id][slot]
	var gem_id: String = ob.get_item_metadata(index)
	player.set_support(skill_id, slot, gem_id)
	if gem_id != "":
		info.text = "%s: %s" % [GemData.GEMS[gem_id]["name"], GemData.GEMS[gem_id]["desc"]]
