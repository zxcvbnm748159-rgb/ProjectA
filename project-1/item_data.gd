class_name ItemData
extends Resource

const RARITY_NAMES := ["ธรรมดา", "เวทมนตร์", "หายาก"]
const RARITY_COLORS := [
	Color(0.9, 0.9, 0.9),
	Color(0.4, 0.5, 1.0),
	Color(1.0, 0.85, 0.2),
]
const SLOT_NAMES := {"weapon": "อาวุธ", "armor": "เกราะ", "ring": "แหวน"}
const STAT_NAMES := {
	"damage": "พลังโจมตี",
	"max_health": "เลือดสูงสุด",
	"speed_pct": "ความเร็วเดิน",
	"max_mana": "มานาสูงสุด",
	"mana_regen": "ฟื้นมานาต่อวินาที",
	"skill_dmg_pct": "ดาเมจสกิล",
	"cdr_pct": "ลดคูลดาวน์",
}

@export var item_name: String = ""
@export var slot: String = "weapon"
@export var rarity: int = 0
@export var stats: Dictionary = {}


func get_color() -> Color:
	return RARITY_COLORS[rarity]


func get_description() -> String:
	var text: String = "%s\n%s | %s\n" % [item_name, RARITY_NAMES[rarity], SLOT_NAMES[slot]]
	for key in stats:
		if key.ends_with("_pct"):
			text += "+%d%% %s\n" % [stats[key], STAT_NAMES[key]]
		else:
			text += "+%d %s\n" % [stats[key], STAT_NAMES[key]]
	return text
