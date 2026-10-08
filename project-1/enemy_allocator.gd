class_name EnemyAllocator
extends RefCounted


static func allocate(enemy: Node, wave: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(enemy.get_instance_id()) + wave
	var roll: float = rng.randf()
	
	var etype: int = enemy.ENEMY_TYPE.BASIC
	
	# ระลอก 1-3: ลูกเหล้า 30% (roll 0-0.3)
	if wave < 4 and roll < 0.3:
		etype = enemy.ENEMY_TYPE.MINION
	# ระลอก 3+: ตัวอึด 20% (roll 0.3-0.5)
	elif wave >= 3 and roll >= 0.3 and roll < 0.5:
		etype = enemy.ENEMY_TYPE.TANK
	# อื่น ๆ: ปกติ (roll 0.5+)
	
	# ถ้าถูกตั้งค่าเป็น Boss อยู่แล้ว (เช่น จาก Spawner) ให้คงค่าไว้
	if enemy.enemy_type != enemy.ENEMY_TYPE.BOSS:
		enemy.set_type(etype)
	else:
		etype = enemy.ENEMY_TYPE.BOSS
		
	_load_model(enemy, etype, wave)


static func _load_model(enemy: Node, etype: int, wave: int):
	var model_node = enemy.get_node_or_null("Model")
	
	var model_path: String = "res://models/enemy.gltf"
	var scale_mult: float = 1.0
	
	match etype:
		enemy.ENEMY_TYPE.MINION:
			model_path = "res://models/enemy_minion.gltf"
			scale_mult = 0.6
		enemy.ENEMY_TYPE.TANK:
			model_path = "res://models/enemy_tank.gltf"
			scale_mult = 1.3
		enemy.ENEMY_TYPE.BOSS:
			model_path = "res://models/enemy_boss.gltf"
			scale_mult = 2.0
	
	# Fallback กรณีไม่มีไฟล์โมเดลเฉพาะ ให้ใช้ไฟล์หลักแทน
	if not ResourceLoader.exists(model_path):
		print("❌ ไม่พบไฟล์: ", model_path, " -> ใช้ไฟล์หลัก res://models/enemy.gltf แทน")
		model_path = "res://models/enemy.gltf"
	else:
		print("✅ พบไฟล์โมเดล: ", model_path)
	
	if ResourceLoader.exists(model_path):
		var new_model = load(model_path).instantiate()
		
		# หากมี Node Model เดิมอยู่ ให้เคลียร์ทิ้ง
		if model_node != null:
			model_node.name = "Model_Old"
			model_node.queue_free()
		
		# ✅ ใส่ Node โมเดลใหม่เป็น Child ของ Enemy โดยตรง (เพื่อตามตำแหน่ง Enemy)
		enemy.add_child(new_model)
		new_model.name = "Model"
		new_model.position = Vector3.ZERO
		new_model.scale = Vector3(scale_mult, scale_mult, scale_mult)
		
		# เรียกปรับฟังก์ชัน Pixelate และเก็บข้อมูล Mesh
		if ClassDB.class_exists("ModelUtil") or Engine.has_singleton("ModelUtil"):
			ModelUtil.pixelate(new_model)
			if "model_meshes" in enemy:
				enemy.model_meshes = ModelUtil.collect_meshes(new_model)
