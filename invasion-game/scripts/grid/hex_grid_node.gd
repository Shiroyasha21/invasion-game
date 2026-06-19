extends Node2D
class_name HexGridNode

signal unlocked_radius_changed(new_radius: int)

@export var hex_size: float = 64.0
@export var max_grid_radius: int = 7  # full board size, generated once
@export var initial_unlocked_radius: int = 3  # how much is playable/visible at start

var tiles: Dictionary = {}  # Vector2i -> bool (occupied)
var unlocked_radius: int
var highlighted_hexes: Array[Vector2i] = []
var _highlight_pulse: float = 0.0


func _ready() -> void:
	unlocked_radius = initial_unlocked_radius
	_generate_tiles()


func unlock_more() -> void:
	if unlocked_radius >= max_grid_radius:
		return
	unlocked_radius += 1
	emit_signal("unlocked_radius_changed", unlocked_radius)
	queue_redraw()


func _process(delta: float) -> void:
	if highlighted_hexes.is_empty():
		return
	_highlight_pulse += delta
	queue_redraw()


func set_highlights(hexes: Array[Vector2i]) -> void:
	highlighted_hexes = hexes
	_highlight_pulse = 0.0
	queue_redraw()


func clear_highlights() -> void:
	highlighted_hexes = []
	queue_redraw()


func _generate_tiles() -> void:
	tiles.clear()
	for hex in HexGrid.filled_circle(Vector2i.ZERO, max_grid_radius):
		tiles[hex] = false
	queue_redraw()


func _draw() -> void:
	var pulse := (sin(_highlight_pulse * 3.0) + 1.0) / 2.0

	for hex in tiles.keys():
		var center := HexGrid.hex_to_pixel(hex, hex_size)
		var pts := HexGrid.corners(center, hex_size)
		var locked := HexGrid.distance(Vector2i.ZERO, hex) > unlocked_radius

		var fill_color := Color(0.15, 0.18, 0.25)
		var outline_color := Color(0.4, 0.5, 0.7, 0.6)
		var outline_width := 1.5

		if locked:
			fill_color = Color(0.05, 0.05, 0.07, 0.6)
			outline_color = Color(0.2, 0.2, 0.25, 0.3)
		elif hex == Vector2i.ZERO:
			fill_color = Color(0.3, 0.2, 0.5)
		elif hex in highlighted_hexes:
			fill_color = Color(0.8, 0.3, 0.1, 0.4 + pulse * 0.4)
			outline_color = Color(1.0, 0.4, 0.1, 0.9)
			outline_width = 3.0

		draw_colored_polygon(pts, fill_color)
		draw_polyline(pts + PackedVector2Array([pts[0]]), outline_color, outline_width)


func hex_at_pixel(pos: Vector2) -> Vector2i:
	return HexGrid.pixel_to_hex(pos - global_position, hex_size)


func hex_grid_to_pixel(hex: Vector2i) -> Vector2:
	return HexGrid.hex_to_pixel(hex, hex_size) + global_position


func is_valid_tile(hex: Vector2i) -> bool:
	return tiles.has(hex) and HexGrid.distance(Vector2i.ZERO, hex) <= unlocked_radius


func is_occupied(hex: Vector2i) -> bool:
	return tiles.get(hex, false)


func set_occupied(hex: Vector2i, occupied: bool) -> void:
	if tiles.has(hex):
		tiles[hex] = occupied
		queue_redraw()
