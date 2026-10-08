extends Node3D

var radius: float = 1.0
var max_radius: float = 12.0
var expand_speed: float = 30.0
var time_left: float = 0.3

func _ready():
	# สร้าง sphere mesh ที่สีฟ้าไฟ
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = 0.1
	mesh_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.8, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0)
	mesh_inst.material_override = mat
	
	add_child(mesh_inst)

func _process(delta):
	radius += expand_speed * delta
	time_left -= delta
	
	if radius >= max_radius or time_left <= 0:
		queue_free()
		return
	
	# อัพเดต mesh scale
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").scale = Vector3(radius / 1.0, 0.1, radius / 1.0)
