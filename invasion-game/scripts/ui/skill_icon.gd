extends Control
class_name SkillIcon

enum IconType { SHIELD, VINES, WEAKEN }

@export var icon_type: IconType = IconType.SHIELD


func _draw() -> void:
	var center := size / 2.0
	var r := minf(size.x, size.y) * 0.4
	draw_set_transform(center, 0.0, Vector2.ONE)
	match icon_type:
		IconType.VINES:
			_draw_vines(r)
		IconType.WEAKEN:
			_draw_weaken(r)
		_:
			_draw_shield(r)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shield(r: float) -> void:
	var pts := PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.8, -r * 0.4), Vector2(r * 0.7, r * 0.5),
		Vector2(0, r), Vector2(-r * 0.7, r * 0.5), Vector2(-r * 0.8, -r * 0.4),
	])
	draw_colored_polygon(pts, Color(0.3, 0.6, 0.9))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.9, 0.95, 1.0), 2.0)


func _draw_vines(r: float) -> void:
	draw_circle(Vector2.ZERO, r, Color(0.15, 0.4, 0.15))
	for i in 3:
		var angle := i * TAU / 3.0
		var tip := Vector2(cos(angle), sin(angle)) * r * 0.9
		draw_line(Vector2.ZERO, tip, Color(0.3, 0.7, 0.25), 3.0)
		draw_circle(tip, r * 0.18, Color(0.4, 0.8, 0.3))


func _draw_weaken(r: float) -> void:
	draw_circle(Vector2.ZERO, r, Color(0.5, 0.15, 0.5))
	draw_line(Vector2(-r * 0.5, -r * 0.3), Vector2(r * 0.5, r * 0.3), Color(0.9, 0.9, 0.95), 3.0)
	draw_line(Vector2(-r * 0.5, r * 0.3), Vector2(r * 0.5, -r * 0.3), Color(0.9, 0.9, 0.95), 3.0)
