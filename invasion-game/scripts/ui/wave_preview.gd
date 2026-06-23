extends Node2D
class_name WavePreview

class Marker:
	var marker_position: Vector2
	var age: float = 0.0
	var lifetime: float = 1.0
	var color: Color = Color(1.0, 0.4, 0.1, 0.9)
	var radius: float = 20.0
	var is_expanding: bool = false

var _markers: Array[Marker] = []


func init(_grid: HexGridNode) -> void:
	pass  # kept for compatibility with game.gd's init call


func flash_warning(pos: Vector2) -> void:
	_add_marker(pos, 1.0, Color(1.0, 0.4, 0.1, 0.9), 20.0, false)


func flash_mini_boss_warning(pos: Vector2) -> void:
	_add_marker(pos, 1.6, Color(1.0, 0.1, 0.1, 0.95), 34.0, false)


# Vines spreading outward from the centerpiece as an expanding ring. The
# ultimate's radius is large, so the wave takes longer to sweep across it.
func flash_vine_wave(center: Vector2, max_radius: float) -> void:
	_add_marker(center, 1.3, Color(0.35, 0.9, 0.3, 0.9), max_radius, true)
	_add_marker(center, 1.3, Color(0.25, 0.7, 0.25, 0.65), max_radius * 0.75, true)
	_add_marker(center, 1.3, Color(0.5, 1.0, 0.4, 0.5), max_radius * 0.5, true)


func _add_marker(pos: Vector2, lifetime: float, color: Color, radius: float, expanding: bool) -> void:
	var m := Marker.new()
	m.marker_position = pos
	m.lifetime = lifetime
	m.color = color
	m.radius = radius
	m.is_expanding = expanding
	_markers.append(m)


func _process(delta: float) -> void:
	if _markers.is_empty():
		return
	var i := _markers.size() - 1
	while i >= 0:
		_markers[i].age += delta
		if _markers[i].age >= _markers[i].lifetime:
			_markers.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for m in _markers:
		var t: float = m.age / m.lifetime
		var alpha := 1.0 - t

		if m.is_expanding:
			var r := lerpf(0.0, m.radius, t)
			var c: Color = m.color
			c.a *= alpha
			draw_arc(m.marker_position, r, 0, TAU, 48, c, 4.0)
			continue

		var pulse := (sin(t * TAU * 3.0) + 1.0) / 2.0
		var c: Color = m.color
		c.a *= alpha
		draw_circle(m.marker_position, m.radius * 0.6 + pulse * m.radius * 0.2, c)
		draw_arc(m.marker_position, m.radius, 0, TAU, 24, c, 2.5)
