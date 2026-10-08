class_name Torch
extends Node3D

var light: OmniLight3D
var flame: MeshInstance3D
var t: float = 0.0


func _ready():
	t = randf() * 10.0   # แต่ละอันกะพริบไม่พร้อมกัน

	# เสาไม้
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.25, 1.4, 0.25)
	post.mesh = pm
	post.position.y = 0.7
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.25, 0.15, 0.08)
	post.material_override = pmat
	add_child(post)

	# เปลวไฟ: กล่องส้มสว่างเอง
	flame = MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.35, 0.45, 0.35)
	flame.mesh = fm
	flame.position.y = 1.6
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.6, 0.15)
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.5, 0.1)
	fmat.emission_energy_multiplier = 3.0
	flame.material_override = fmat
	add_child(flame)

	# แสงไฟส่องรอบ ๆ
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 3.0
	light.omni_range = 9.0
	light.position.y = 1.9
	add_child(light)


func _process(delta):
	t += delta
	# ซ้อนคลื่นสองความถี่ให้กะพริบดูเป็นธรรมชาติ
	var flick: float = 1.0 + sin(t * 11.0) * 0.08 + sin(t * 23.0 + 1.3) * 0.06
	light.light_energy = 3.0 * flick
	flame.scale.y = 0.9 + (flick - 1.0) * 2.0
