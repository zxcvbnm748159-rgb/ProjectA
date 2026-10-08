extends Node3D

@export var half_size: float = 29.0      # ระยะเดินได้สุด ตั้งเท่าเดิมที่ใช้อยู่
@export var wall_height: float = 1.0     # ความสูงของ collision (ล่องหน)
@export var wall_thickness: float = 0.2
@export var torch_spacing: float = 20.0  # ยิ่งมากคบเพลิงยิ่งน้อย

# กำแพงที่มองเห็น: ฝั่งไกลกล้องสูง ฝั่งใกล้กล้องเตี้ย จะได้ไม่บังตัวละคร
@export var far_wall_height: float = 3.0
@export var near_wall_height: float = 0.8
@export var visual_thickness: float = 1.0


func _ready():
	_make_collision_walls()
	_style_floor()
	_build_visual_walls()
	_place_torches()


func _make_collision_walls():
	var length: float = half_size * 2.0 + wall_thickness * 2.0
	var off: float = half_size + wall_thickness / 2.0
	var y: float = wall_height / 2.0
	_make_wall(Vector3(0, y, -off), Vector3(length, wall_height, wall_thickness))
	_make_wall(Vector3(0, y, off), Vector3(length, wall_height, wall_thickness))
	_make_wall(Vector3(off, y, 0), Vector3(wall_thickness, wall_height, length))
	_make_wall(Vector3(-off, y, 0), Vector3(wall_thickness, wall_height, length))


func _make_wall(pos: Vector3, size: Vector3):
	var body := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape_node.shape = box
	body.add_child(shape_node)
	add_child(body)
	body.position = pos


func _style_floor():
	var floor_node = get_node_or_null("Floor")
	if floor_node:
		floor_node.material = PixelArt.stone_material(Color(0.24, 0.24, 0.28), 3, "flag", 0.5)


func _build_visual_walls():
	var mat: StandardMaterial3D = PixelArt.stone_material(Color(0.32, 0.30, 0.34), 7, "brick", 0.5)
	var off: float = half_size + visual_thickness / 2.0
	var full: float = (half_size + visual_thickness) * 2.0   # ยาวคลุมมุม
	var mid: float = half_size * 2.0                          # ยาวเฉพาะช่วงกลาง ไม่ซ้อนมุม
	# ทิศ: เหนือ(-z) และตะวันตก(-x) อยู่ไกลกล้อง / ใต้(+z) และตะวันออก(+x) อยู่ใกล้กล้อง
	_visual_wall(Vector3(0, 0, -off), Vector3(full, far_wall_height, visual_thickness), mat)
	_visual_wall(Vector3(0, 0, off), Vector3(full, near_wall_height, visual_thickness), mat)
	_visual_wall(Vector3(-off, 0, 0), Vector3(visual_thickness, far_wall_height, mid), mat)
	_visual_wall(Vector3(off, 0, 0), Vector3(visual_thickness, near_wall_height, mid), mat)


func _visual_wall(pos: Vector3, size: Vector3, mat: Material):
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	add_child(mi)
	mi.position = Vector3(pos.x, size.y / 2.0, pos.z)


func _place_torches():
	var n: int = maxi(1, int(half_size * 2.0 / torch_spacing))
	var step: float = half_size * 2.0 / n
	var inset: float = half_size - 1.0   # ยืนห่างกำแพงเข้ามา 1 หน่วย
	for i in n:
		var d: float = -half_size + (i + 0.5) * step
		_torch(Vector3(d, 0, -inset))
		_torch(Vector3(d, 0, inset))
		_torch(Vector3(-inset, 0, d))
		_torch(Vector3(inset, 0, d))


func _torch(pos: Vector3):
	var tc := Torch.new()
	add_child(tc)
	tc.position = pos
