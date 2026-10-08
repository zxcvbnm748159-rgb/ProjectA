extends Camera3D

@export var target_path: NodePath
@export var offset := Vector3(8, 11, 8)

@onready var target: Node3D = get_node(target_path)


func _process(_delta):
	global_position = target.global_position + offset
