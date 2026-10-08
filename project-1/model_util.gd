class_name ModelUtil
extends RefCounted


static func collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	_walk(root, result)
	return result


static func _walk(node: Node, result: Array[MeshInstance3D]):
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_walk(child, result)


# ทำให้เท็กซ์เจอร์ของโมเดลคมเป็นพิกเซล (Nearest)
static func pixelate(root: Node):
	for mi in collect_meshes(root):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(i)
			if m is BaseMaterial3D:
				var copy: BaseMaterial3D = m.duplicate() as BaseMaterial3D
				copy.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mi.set_surface_override_material(i, copy)
