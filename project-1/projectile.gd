extends Area3D

var direction := Vector3.FORWARD
var speed := 14.0
var damage := 10
var max_distance := 16.0
var pierce := false
var size := 0.5
var color := Color(1.0, 0.5, 0.1)

var traveled := 0.0
var hit_enemies := []   # จำตัวที่โดนแล้ว กันโดนซ้ำ (สำคัญกับกระสุนทะลุ)

@onready var shape_node: CollisionShape3D = $CollisionShape3D
@onready var mesh_node: MeshInstance3D = $MeshInstance3D


func _ready():
	# โซนตรวจจับเป็นทรงกลม
	var sphere := SphereShape3D.new()
	sphere.radius = size
	shape_node.shape = sphere

	# หน้าตากระสุน: กล่องสว่างเอง ไม่โดนหมอกบัง
	var box := BoxMesh.new()
	box.size = Vector3(size, size, size) * 1.2
	mesh_node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = true
	mesh_node.material_override = mat

	# แสงสีส่องพื้นตามกระสุน
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.5
	light.omni_range = 4.0
	add_child(light)

	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	var step: Vector3 = direction * speed * delta
	global_position += step
	traveled += step.length()
	mesh_node.rotate_y(delta * 8.0)
	mesh_node.rotate_x(delta * 5.0)
	if traveled >= max_distance:
		queue_free()   # ไปไกลสุดระยะแล้ว หายไป


func _on_body_entered(body):
	# สนใจเฉพาะศัตรู (ไม่ชนผู้เล่นหรือของอื่น)
	if not body.is_in_group("enemies"):
		return
	if hit_enemies.has(body):
		return
	hit_enemies.append(body)
	body.take_damage(damage)
	if not pierce:
		queue_free()   # กระสุนธรรมดา ชนแล้วหาย
