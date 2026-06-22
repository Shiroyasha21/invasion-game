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
