class_name PixelArt
extends RefCounted


# วาดเท็กซ์เจอร์ 16x16 พิกเซล pattern = "brick" (อิฐ) หรือ "flag" (แผ่นหินปู)
static func stone_texture(base: Color, seed_val: int, pattern: String) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			# สุ่มความสว่างเล็กน้อยให้ผิวหินไม่เรียบเนียนเกินไป
			var v: float = rng.randf_range(-0.05, 0.05)
			var c := Color(base.r + v, base.g + v, base.b + v)
			var mortar: bool = false
			if pattern == "brick":
				mortar = (y % 8 == 0) or (x == (0 if y < 8 else 8))
			else:
				mortar = (x == 0 or y == 0)
			if mortar:
				c = c.darkened(0.45)   # ร่องปูนสีเข้ม
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func stone_material(base: Color, seed_val: int, pattern: String, tiles: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = stone_texture(base, seed_val, pattern)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST   # พิกเซลคม ไม่เบลอ
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(tiles, tiles, tiles)   # 0.5 = ลายซ้ำทุก 2 หน่วย
	m.roughness = 1.0
	return m
