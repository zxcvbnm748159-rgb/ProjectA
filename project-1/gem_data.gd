class_name GemData
extends RefCounted

# ข้อมูล gem ทั้งหมด เพิ่ม gem ใหม่ได้โดยเพิ่มอีกก้อน
# ค่าที่ใช้ได้: extra (จำนวนกระสุนเพิ่ม), dmg (ตัวคูณดาเมจ),
# mana (ตัวคูณมานา), cd (ตัวคูณคูลดาวน์), pierce (ทะลุ)
const GEMS := {
	"multi": {
		"name": "ยิงหลายลูก",
		"desc": "ยิงเพิ่ม 2 ลูกเป็นรูปพัด | ดาเมจต่อลูก -30% | มานา x1.4",
		"extra": 2, "dmg": 0.7, "mana": 1.4,
	},
	"pierce": {
		"name": "ทะลุ",
		"desc": "กระสุนทะลุศัตรูได้ทุกตัว | มานา x1.2",
		"pierce": true, "mana": 1.2,
	},
	"power": {
		"name": "พลังเพิ่ม",
		"desc": "ดาเมจ +40% | มานา x1.5",
		"dmg": 1.4, "mana": 1.5,
	},
	"quick": {
		"name": "ร่ายไว",
		"desc": "คูลดาวน์ -30% | มานา x1.2",
		"cd": 0.7, "mana": 1.2,
	},
}


# รวมผลของ gem ที่เสียบอยู่ทั้งหมดของสกิลหนึ่งเป็นก้อนเดียว
static func combine(ids: Array) -> Dictionary:
	var r: Dictionary = {"extra": 0, "dmg": 1.0, "mana": 1.0, "cd": 1.0, "pierce": false}
	for id in ids:
		if id == "" or not GEMS.has(id):
			continue
		var g: Dictionary = GEMS[id]
		r["extra"] += g.get("extra", 0)
		r["dmg"] *= g.get("dmg", 1.0)
		r["mana"] *= g.get("mana", 1.0)
		r["cd"] *= g.get("cd", 1.0)
		if g.get("pierce", false):
			r["pierce"] = true
	return r


# ข้อความสรุปผลรวม แสดงใต้ช่องเสียบ
static func summarize(ids: Array) -> String:
	var r: Dictionary = combine(ids)
	var text: String = "ยิง %d ลูก | ดาเมจต่อลูก x%.2f | มานา x%.2f | คูลดาวน์ x%.2f" % [
		1 + int(r["extra"]), r["dmg"], r["mana"], r["cd"]]
	if r["pierce"]:
		text += " | ทะลุ"
	return text
