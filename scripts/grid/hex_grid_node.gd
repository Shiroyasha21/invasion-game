extends Node2D
class_name HexGridNode

@export var hex_size: float = 64.0
@export var grid_radius: int = 4  # rings of hexes around center

var tiles: Dictionary = {}  # Vector2i -> bool (occupied)


func _ready() -> void:
	_generate_tiles()


func _generate_tiles() -> void:
	tiles.clear()
	for hex in HexGrid.filled_circle(Vector2i.ZERO, grid_radius):
		tiles[hex] = false
	queue_redraw()


func _draw() -> void:
	for hex in tiles.keys():
		var center := HexGrid.hex_to_pixel(hex, hex_size)
		var pts := HexGrid.corners(center, hex_size)
		# Fill
		var color := Color(0.15, 0.18, 0.25) if hex != Vector2i.ZERO else Color(0.3, 0.2, 0.5)
		draw_colored_polygon(pts, color)
		# Outline
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.4, 0.5, 0.7, 0.6), 1.5)


func hex_at_pixel(pos: Vector2) -> Vector2i:
	return HexGrid.pixel_to_hex(pos - global_position, hex_size)


func is_valid_tile(hex: Vector2i) -> bool:
	return tiles.has(hex)


func is_occupied(hex: Vector2i) -> bool:
	return tiles.get(hex, false)


func set_occupied(hex: Vector2i, occupied: bool) -> void:
	if tiles.has(hex):
		tiles[hex] = occupied
		queue_redraw()
