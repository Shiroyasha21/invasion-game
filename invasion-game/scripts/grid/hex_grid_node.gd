extends Node2D
class_name HexGridNode

signal unlocked_radius_changed(new_radius: int)

@export var hex_size: float = 64.0
@export var max_grid_radius: int = 7  # full board size, generated once
@export var initial_unlocked_radius: int = 3  # how much is playable/visible at start

const GRASS_BASE := Color(0.16, 0.36, 0.14)
const STONE_BASE := Color(0.32, 0.31, 0.33)
const VOID_COLOR := Color(0.04, 0.06, 0.04, 1.0)

var tiles: Dictionary = {}  # Vector2i -> bool (occupied)
var unlocked_radius: int
var highlighted_hexes: Array[Vector2i] = []
var _highlight_pulse: float = 0.0
var _grass_speckles: Dictionary = {}  # Vector2i -> Array[Dictionary] {pos, radius, shade}


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
	_grass_speckles.clear()
	for hex in HexGrid.filled_circle(Vector2i.ZERO, max_grid_radius):
		tiles[hex] = false
		_grass_speckles[hex] = _make_speckles(hex)
	queue_redraw()


# Pre-baked grass-tuft texture per tile so the ground reads as an organic
# field instead of flat-filled hexagons — generated once, not every frame.
func _make_speckles(hex: Vector2i) -> Array:
	var speckles := []
	var center := HexGrid.hex_to_pixel(hex, hex_size)
	for _i in 5:
		var offset := Vector2(randf_range(-hex_size * 0.55, hex_size * 0.55), randf_range(-hex_size * 0.55, hex_size * 0.55))
		speckles.append({
			"pos": center + offset,
			"radius": randf_range(3.0, 7.0),
			"shade": randf_range(-0.07, 0.08),
		})
	return speckles


func _draw() -> void:
	var pulse := (sin(_highlight_pulse * 3.0) + 1.0) / 2.0

	for hex in tiles.keys():
		var center := HexGrid.hex_to_pixel(hex, hex_size)
		var pts := HexGrid.corners(center, hex_size)
		var locked := HexGrid.distance(Vector2i.ZERO, hex) > unlocked_radius

		var base := STONE_BASE if locked else GRASS_BASE
		draw_colored_polygon(pts, base)
		for speckle in _grass_speckles.get(hex, []):
			var shade: float = speckle["shade"]
			var c := base.lightened(shade) if shade > 0.0 else base.darkened(-shade)
			draw_circle(speckle["pos"], speckle["radius"], c)

		if locked:
			continue

		if hex in highlighted_hexes:
			draw_circle(center, hex_size * 0.65, Color(0.95, 0.6, 0.15, 0.2 + pulse * 0.25))
			draw_arc(center, hex_size * 0.65, 0, TAU, 24, Color(1.0, 0.7, 0.2, 0.85), 3.0)

	_draw_circular_edge()


# Rounds off the outermost ring's protruding corners with small void-colored
# circles, so the board reads as a circle instead of the hex tiles' natural
# zigzag silhouette. Only touches the handful of corners that actually stick
# out past the target radius — bounded and small, low-risk if anything's off.
func _draw_circular_edge() -> void:
	var target_radius := float(max_grid_radius) * hex_size * 0.97
	for hex in HexGrid.ring(Vector2i.ZERO, max_grid_radius):
		var center := HexGrid.hex_to_pixel(hex, hex_size)
		for corner in HexGrid.corners(center, hex_size):
			if corner.length() > target_radius:
				draw_circle(corner, hex_size * 0.42, VOID_COLOR)


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
