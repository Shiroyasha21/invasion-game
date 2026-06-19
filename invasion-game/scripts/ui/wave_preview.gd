extends Node2D
class_name WavePreview

var _spawn_points: Array[Vector2] = []
var _pulse: float = 0.0


func init(_grid: HexGridNode) -> void:
	pass  # kept for compatibility with game.gd's init call


func show_preview(spawn_points: Array[Vector2]) -> void:
	_spawn_points = spawn_points
	_pulse = 0.0
	queue_redraw()


func hide_preview() -> void:
	_spawn_points = []
	queue_redraw()


func _process(delta: float) -> void:
	if _spawn_points.is_empty():
		return
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var scale_pulse := (sin(_pulse * 4.0) + 1.0) / 2.0
	for pos in _spawn_points:
		draw_circle(pos, 12.0 + scale_pulse * 4.0, Color(1.0, 0.4, 0.1, 0.5))
		draw_arc(pos, 20.0, 0, TAU, 24, Color(1.0, 0.6, 0.2, 0.9), 2.5)
