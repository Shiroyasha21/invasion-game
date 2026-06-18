extends Node2D
class_name HexGridNode

@export var hex_size: float = 64.0
@export var grid_radius: int = 4  # rings of hexes around center

var tiles: Dictionary = {}  # Vector2i -> bool (occupied)
var highlighted_hexes: Array[Vector2i] = []
var _highlight_pulse: float = 0.0


func _ready() -> void:
	_generate_tiles()


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
	for hex in HexGrid.filled_circle(Vector2i.ZERO, grid_radius):
		tiles[hex] = false
	queue_redraw()


func _draw() -> void:
	var pulse := (sin(_highlight_pulse * 3.0) + 1.0) / 2.0

	for hex in tiles.keys():
		var center := HexGrid.hex_to_pixel(hex, hex_size)
		var pts := HexGrid.corners(center, hex_size)

		var fill_color := Color(0.15, 0.18, 0.25)
		if hex == Vector2i.ZERO:
			fill_color = Color(0.3, 0.2, 0.5)
		elif hex in highlighted_hexes:
			fill_color = Color(0.8, 0.3, 0.1, 0.4 + pulse * 0.4)

		draw_colored_polygon(pts, fill_color)

		var outline_color := Color(1.0, 0.4, 0.1, 0.9) if hex in highlighted_hexes else Color(0.4, 0.5, 0.7, 0.6)
		var outline_width := 3.0 if hex in highlighted_hexes else 1.5
		draw_polyline(pts + PackedVector2Array([pts[0]]), outline_color, outline_width)


func hex_at_pixel(pos: Vector2) -> Vector2i:
	return HexGrid.pixel_to_hex(pos - global_position, hex_size)


func hex_grid_to_pixel(hex: Vector2i) -> Vector2:
	return HexGrid.hex_to_pixel(hex, hex_size) + global_position


func is_valid_tile(hex: Vector2i) -> bool:
	return tiles.has(hex)


func is_occupied(hex: Vector2i) -> bool:
	return tiles.get(hex, false)


func set_occupied(hex: Vector2i, occupied: bool) -> void:
	if tiles.has(hex):
		tiles[hex] = occupied
		queue_redraw()
