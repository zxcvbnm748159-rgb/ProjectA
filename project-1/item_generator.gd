class_name ItemGenerator
extends RefCounted

const BASES := {
	"weapon": ["ดาบสนิม", "ขวานกระดูก", "คทาไม้ผุ"],
	"armor": ["เสื้อหนังขาด", "เกราะโซ่เก่า", "ผ้าคลุมมืด"],
	"ring": ["แหวนทองแดง", "แหวนกระดูก", "แหวนเลือด"],
}

const AFFIXES := [
	{"stat": "damage", "lo": 2, "hi": 6},
	{"stat": "max_health", "lo": 10, "hi": 30},
	{"stat": "speed_pct", "lo": 3, "hi": 10},
	{"stat": "max_mana", "lo": 8, "hi": 20},
	{"stat": "mana_regen", "lo": 1, "hi": 3},
	{"stat": "skill_dmg_pct", "lo": 8, "hi": 25},
	{"stat": "cdr_pct", "lo": 5, "hi": 15},
]


static func roll() -> ItemData:
	var item := ItemData.new()
	item.slot = BASES.keys().pick_random()
	item.item_name = BASES[item.slot].pick_random()

	var r: float = randf()
	if r < 0.6:
		item.rarity = 0
	elif r < 0.9:
		item.rarity = 1
	else:
		item.rarity = 2

	var count: int = item.rarity + 1
	var pool: Array = AFFIXES.duplicate()
	pool.shuffle()
	for i in count:
		var a: Dictionary = pool[i]
		item.stats[a["stat"]] = randi_range(a["lo"], a["hi"])
	return item
