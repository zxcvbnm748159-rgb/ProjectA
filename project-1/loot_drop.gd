extends Node3D

var item: ItemData
var t := 0.0

@onready var mesh_node: MeshInstance3D = $MeshInstance3D


func _ready():
	add_to_group("loot")   # แปะป้ายกลุ่ม ให้ UI หาเจอ
	var color: Color = item.get_color()

	# --- กล่องของ ---
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	mesh_node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = true
	mesh_node.material_override = mat

	# --- ลำแสงพุ่งขึ้นฟ้า ---
	var beam_height := 5.0 + item.rarity * 3.0
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(0.4, beam_height, 0.4)
	beam.mesh = beam_mesh
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(color.r, color.g, color.b, 0.45)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.disable_fog = true
	beam.material_override = beam_mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position.y = beam_height / 2.0
	add_child(beam)

	# --- แสงสีส่องพื้น ---
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.position.y = 1.0
	add_child(light)


func _process(delta):
	t += delta
	mesh_node.position.y = 0.5 + sin(t * 3.0) * 0.15
	mesh_node.rotate_y(delta * 2.0)
