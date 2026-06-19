extends Node2D
class_name WavePreview

class Marker:
	var marker_position: Vector2
	var age: float = 0.0
	var lifetime: float = 1.0
	var color: Color = Color(1.0, 0.4, 0.1, 0.9)
	var radius: float = 20.0

var _markers: Array[Marker] = []


func init(_grid: HexGridNode) -> void:
	pass  # kept for compatibility with game.gd's init call


func flash_warning(pos: Vector2) -> void:
	_add_marker(pos, 1.0, Color(1.0, 0.4, 0.1, 0.9), 20.0)


func flash_mini_boss_warning(pos: Vector2) -> void:
	_add_marker(pos, 1.6, Color(1.0, 0.1, 0.1, 0.95), 34.0)


func _add_marker(pos: Vector2, lifetime: float, color: Color, radius: float) -> void:
	var m := Marker.new()
	m.marker_position = pos
	m.lifetime = lifetime
	m.color = color
	m.radius = radius
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
		var pulse := (sin(t * TAU * 3.0) + 1.0) / 2.0
		var alpha := 1.0 - t
		var c: Color = m.color
		c.a *= alpha
		draw_circle(m.marker_position, m.radius * 0.6 + pulse * m.radius * 0.2, c)
		draw_arc(m.marker_position, m.radius, 0, TAU, 24, c, 2.5)
