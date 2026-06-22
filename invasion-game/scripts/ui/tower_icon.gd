extends Control
class_name TowerIcon

@export var animal_type: TowerData.AnimalType = TowerData.AnimalType.FROG
@export var body_color: Color = Color(0.3, 0.85, 0.4)


func _draw() -> void:
	var center := size / 2.0
	var r := minf(size.x, size.y) * 0.42
	draw_set_transform(center, 0.0, Vector2.ONE)
	match animal_type:
		TowerData.AnimalType.BEAR:
			_draw_bear(r)
		TowerData.AnimalType.MONKEY:
			_draw_monkey(r)
		TowerData.AnimalType.OWL:
			_draw_owl(r)
		TowerData.AnimalType.GRENADIER:
			_draw_grenadier(r)
		_:
			_draw_frog(r)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_frog(r: float) -> void:
	draw_set_transform(size / 2.0, 0.0, Vector2(1.1, 0.85))
	draw_circle(Vector2.ZERO, r, body_color)
	draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
	for side in [-1.0, 1.0]:
		var eye_pos := Vector2(r * 0.2, side * r * 0.55)
		draw_circle(eye_pos, r * 0.26, Color(0.95, 0.98, 0.9))
		draw_circle(eye_pos, r * 0.13, Color(0.05, 0.05, 0.05))


func _draw_bear(r: float) -> void:
	draw_circle(Vector2.ZERO, r, body_color)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(-r * 0.5, side * r * 0.65), r * 0.3, body_color.darkened(0.2))
	draw_circle(Vector2(r * 0.6, 0), r * 0.34, body_color.darkened(0.15))
	draw_circle(Vector2(r * 0.85, 0), r * 0.1, Color(0.08, 0.08, 0.08))


func _draw_monkey(r: float) -> void:
	draw_circle(Vector2.ZERO, r, body_color)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(-r * 0.15, side * r * 0.9), r * 0.28, body_color.lightened(0.1))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(r * 0.4, side * r * 0.32), r * 0.16, Color(0.05, 0.05, 0.05))


func _draw_owl(r: float) -> void:
	for side in [-1.0, 1.0]:
		draw_set_transform(size / 2.0 + Vector2(0, side * r * 0.25), 0.0, Vector2(0.55, 1.3))
		draw_circle(Vector2(side * r * 0.75, 0), r * 0.65, body_color.darkened(0.15))
		draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, r, body_color)
	for side in [-1.0, 1.0]:
		var eye_pos := Vector2(r * 0.3, side * r * 0.38)
		draw_circle(eye_pos, r * 0.3, Color(1.0, 0.95, 0.8))
		draw_circle(eye_pos, r * 0.15, Color(0.05, 0.05, 0.05))
	var beak := PackedVector2Array([
		Vector2(r * 0.85, -r * 0.12), Vector2(r * 1.25, 0), Vector2(r * 0.85, r * 0.12),
	])
	draw_colored_polygon(beak, Color(0.9, 0.6, 0.1))


func _draw_grenadier(r: float) -> void:
	var body_pts := PackedVector2Array([
		Vector2(-r * 0.5, -r * 0.65), Vector2(r * 0.5, -r * 0.65),
		Vector2(r * 0.5, r * 0.75), Vector2(-r * 0.5, r * 0.75),
	])
	draw_colored_polygon(body_pts, body_color)
	draw_circle(Vector2(0, -r * 0.95), r * 0.42, Color(0.85, 0.7, 0.55))
	draw_arc(Vector2(0, -r * 1.0), r * 0.48, PI, TAU, 16, Color(0.25, 0.35, 0.2), 5.0)
	draw_line(Vector2.ZERO, Vector2(r * 0.9, 0), Color(0.2, 0.2, 0.2), 6.0)
	draw_circle(Vector2(r * 0.9, 0), r * 0.22, Color(0.25, 0.5, 0.2))
