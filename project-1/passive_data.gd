class_name PassiveData
extends RefCounted

# pos = ตำแหน่งบนหน้าต่าง (พิกเซล), links = โหนดที่ต่อถึงกัน
# start = โหนดเริ่มต้น เปิดให้ฟรี ไม่เสียแต้ม
const NODES := {
	"start": {
		"name": "จุดเริ่มต้น", "pos": Vector2(300, 240),
		"stats": {}, "links": ["dmg1", "hp1", "mana1", "spd1"], "start": true,
	},
	# --- สายโจมตี (ขึ้น) ---
	"dmg1": {
		"name": "กำลังแขน", "pos": Vector2(300, 160),
		"stats": {"damage": 3}, "links": ["start", "dmg2"],
	},
	"dmg2": {
		"name": "คมดาบ", "pos": Vector2(300, 80),
		"stats": {"damage": 4, "skill_dmg_pct": 5}, "links": ["dmg1", "skill1"],
	},
	"skill1": {
		"name": "เวทเพลิง", "pos": Vector2(380, 40),
		"stats": {"skill_dmg_pct": 15}, "links": ["dmg2"],
	},
	# --- สายเลือด (ซ้าย) ---
	"hp1": {
		"name": "ผิวหนา", "pos": Vector2(210, 240),
		"stats": {"max_health": 20}, "links": ["start", "hp2"],
	},
	"hp2": {
		"name": "หัวใจเหล็ก", "pos": Vector2(120, 240),
		"stats": {"max_health": 30}, "links": ["hp1", "hp3"],
	},
	"hp3": {
		"name": "อึดถึกทน", "pos": Vector2(60, 160),
		"stats": {"max_health": 40, "damage": 2}, "links": ["hp2"],
	},
	# --- สายมานา (ขวา) ---
	"mana1": {
		"name": "จิตนิ่ง", "pos": Vector2(390, 240),
		"stats": {"max_mana": 10}, "links": ["start", "mana2"],
	},
	"mana2": {
		"name": "ธารมานา", "pos": Vector2(480, 240),
		"stats": {"mana_regen": 2}, "links": ["mana1", "mana3"],
	},
	"mana3": {
		"name": "เวทเร็ว", "pos": Vector2(540, 160),
		"stats": {"cdr_pct": 8, "max_mana": 10}, "links": ["mana2"],
	},
	# --- สายความเร็ว (ลง) ---
	"spd1": {
		"name": "ก้าวเบา", "pos": Vector2(300, 320),
		"stats": {"speed_pct": 6}, "links": ["start", "spd2"],
	},
	"spd2": {
		"name": "ลมใต้เท้า", "pos": Vector2(300, 400),
		"stats": {"speed_pct": 8, "cdr_pct": 5}, "links": ["spd1"],
	},
}


static func describe(stats: Dictionary) -> String:
	if stats.is_empty():
		return "ไม่มีโบนัส"
	var lines: PackedStringArray = []
	for key in stats:
		var label: String = ItemData.STAT_NAMES.get(key, key)
		if key.ends_with("_pct"):
			lines.append("+%d%% %s" % [stats[key], label])
		else:
			lines.append("+%d %s" % [stats[key], label])
	return "\n".join(lines)
