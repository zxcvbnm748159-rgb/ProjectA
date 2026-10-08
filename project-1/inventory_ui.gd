extends PanelContainer

const SLOTS := ["weapon", "armor", "ring"]

@onready var item_list: ItemList = $VBox/ItemList
@onready var detail: Label = $VBox/Detail
@onready var equipped_label: Label = $VBox/Equipped
@onready var equipped_list: ItemList = $VBox/EquippedList

var player


func _ready():
	visible = false
	item_list.item_selected.connect(_on_selected)
	item_list.item_activated.connect(_on_activated)
	equipped_list.item_selected.connect(_on_equipped_selected)
	equipped_list.item_activated.connect(_on_equipped_activated)
# รอให้ Node เข้าสู่ Scene Tree สมบูรณ์
	if not is_inside_tree():
		await tree_entered
		
	await get_tree().process_frame

	# เช็กความปลอดภัยก่อนเรียกใช้งาน get_tree()
	if get_tree():
		player = get_tree().get_first_node_in_group("player")
		if player and player.has_signal("inventory_changed"):
			# ตรวจสอบก่อนว่าเคย connect ไปแล้วหรือยังเพื่อป้องกัน signal ซ้ำ
			if not player.inventory_changed.is_connected(refresh):
				player.inventory_changed.connect(refresh)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_I:
		visible = not visible
		if visible:
			refresh()


func refresh():
	if player == null:
		return

	# รายการของในกระเป๋า
	item_list.clear()
	for item in player.inventory:
		var idx = item_list.add_item("%s [%s]" % [item.item_name, ItemData.SLOT_NAMES[item.slot]])
		item_list.set_item_custom_fg_color(idx, item.get_color())
	detail.text = "คลิกดูค่า / ดับเบิลคลิกเพื่อสวมใส่ (ช่องล่าง: ดับเบิลคลิกเพื่อถอด)"

	# รายการช่องสวมใส่ 3 ช่อง
	equipped_list.clear()
	for slot in SLOTS:
		var slot_name: String = ItemData.SLOT_NAMES[slot]
		if player.equipped.has(slot):
			var it: ItemData = player.equipped[slot]
			var idx = equipped_list.add_item("%s: %s" % [slot_name, it.item_name])
			equipped_list.set_item_custom_fg_color(idx, it.get_color())
		else:
			var idx = equipped_list.add_item("%s: (ว่าง)" % slot_name)
			equipped_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))

	equipped_label.text = "โจมตี %d | เลือด %d | ความเร็ว %.1f\nมานา %d | ฟื้นมานา %.1f/วิ | ดาเมจสกิล x%.2f | ลดคูลดาวน์ %d%%" % [
		player.attack_damage, player.max_health, player.speed,
		player.max_mana, player.mana_regen, player.skill_dmg_mult, int(player.cdr * 100)]


func _on_selected(index: int):
	detail.text = player.inventory[index].get_description()


func _on_activated(index: int):
	player.equip(player.inventory[index])


func _on_equipped_selected(index: int):
	var slot: String = SLOTS[index]
	if player.equipped.has(slot):
		detail.text = player.equipped[slot].get_description()


func _on_equipped_activated(index: int):
	player.unequip(SLOTS[index])
