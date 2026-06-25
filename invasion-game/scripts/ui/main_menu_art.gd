extends Control

# Hand-drawn main menu backdrop, in the same procedural-shapes style as the
# rest of the game's art (CenterPiece, TowerIcon) — no image assets needed.


func _draw() -> void:
	var w := size.x
	var h := size.y

	_draw_sky(w, h)
	_draw_sun(w, h)
	_draw_hills(w, h)
	_draw_tree(w, h)
	_draw_critters(w, h)


func _draw_sky(w: float, h: float) -> void:
	var top := Color(0.09, 0.16, 0.1)
	var bottom := Color(0.16, 0.28, 0.14)
	var bands := 24
	for i in bands:
		var t0 := float(i) / bands
		var t1 := float(i + 1) / bands
		draw_rect(Rect2(0, h * t0, w, h * (t1 - t0) + 1.0), top.lerp(bottom, t0))


func _draw_sun(w: float, h: float) -> void:
	var pos := Vector2(w * 0.5, h * 0.22)
	draw_circle(pos, 110.0, Color(1.0, 0.92, 0.55, 0.12))
	draw_circle(pos, 70.0, Color(1.0, 0.92, 0.6, 0.22))
	draw_circle(pos, 38.0, Color(1.0, 0.95, 0.75, 0.9))


func _draw_hills(w: float, h: float) -> void:
	var far := PackedVector2Array([
		Vector2(0, h * 0.62), Vector2(w * 0.3, h * 0.56), Vector2(w * 0.6, h * 0.64),
		Vector2(w, h * 0.58), Vector2(w, h), Vector2(0, h),
	])
	draw_colored_polygon(far, Color(0.12, 0.22, 0.13))

	var near := PackedVector2Array([
		Vector2(0, h * 0.74), Vector2(w * 0.35, h * 0.68), Vector2(w * 0.7, h * 0.76),
		Vector2(w, h * 0.7), Vector2(w, h), Vector2(0, h),
	])
	draw_colored_polygon(near, Color(0.08, 0.16, 0.09))


func _draw_tree(w: float, h: float) -> void:
	var base := Vector2(w * 0.5, h * 0.72)

	draw_set_transform(base + Vector2(10, 8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 95.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var trunk_w := 34.0
	var trunk_h := 110.0
	draw_rect(Rect2(base - Vector2(trunk_w * 0.5, trunk_h), Vector2(trunk_w, trunk_h)), Color(0.42, 0.27, 0.13))
	draw_rect(Rect2(base - Vector2(trunk_w * 0.5, trunk_h), Vector2(trunk_w * 0.3, trunk_h)), Color(0.36, 0.22, 0.1))

	var canopy_center := base - Vector2(0, trunk_h + 60.0)
	for offset in [Vector2(-70, 20), Vector2(70, 15), Vector2(0, -35), Vector2(-35, -10), Vector2(40, -15)]:
		draw_circle(canopy_center + offset, 70.0, Color(0.18, 0.55, 0.2))
	draw_circle(canopy_center, 95.0, Color(0.2, 0.62, 0.24))

	var flower_positions: Array[Vector2] = [
		Vector2(-60, 10), Vector2(55, -5), Vector2(-10, -55),
		Vector2(75, 30), Vector2(-80, -25), Vector2(20, 50),
	]
	for pos in flower_positions:
		var p := canopy_center + pos
		draw_circle(p, 7.0, Color(1.0, 0.78, 0.86))
		draw_circle(p, 3.5, Color(1.0, 0.95, 0.45))


func _draw_critters(w: float, h: float) -> void:
	# Small frog peeking from the grass — ties the menu to the towers in-game.
	var frog_pos := Vector2(w * 0.5 - 150.0, h * 0.86)
	draw_set_transform(frog_pos, 0.0, Vector2(1.1, 0.85))
	draw_circle(Vector2.ZERO, 22.0, Color(0.3, 0.85, 0.4))
	draw_set_transform(frog_pos, 0.0, Vector2.ONE)
	for side in [-1.0, 1.0]:
		var eye := Vector2(5.0, side * 12.0)
		draw_circle(eye, 6.0, Color(0.95, 0.98, 0.9))
		draw_circle(eye, 3.0, Color(0.05, 0.05, 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Owl on the other side.
	var owl_pos := Vector2(w * 0.5 + 150.0, h * 0.85)
	draw_set_transform(owl_pos, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 20.0, Color(0.55, 0.42, 0.28))
	for side in [-1.0, 1.0]:
		var eye := Vector2(6.0, side * 7.5)
		draw_circle(eye, 6.0, Color(1.0, 0.95, 0.8))
		draw_circle(eye, 3.0, Color(0.05, 0.05, 0.05))
	var beak := PackedVector2Array([
		Vector2(17.0, -2.5), Vector2(25.0, 0), Vector2(17.0, 2.5),
	])
	draw_colored_polygon(beak, Color(0.9, 0.6, 0.1))
