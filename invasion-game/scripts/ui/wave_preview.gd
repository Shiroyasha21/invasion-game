extends CanvasLayer

const ARROW_COLOR := Color(1.0, 0.4, 0.2, 0.85)
const PULSE_SPEED := 2.0

var _directions: Array[int] = []
var _pulse_timer: float = 0.0
var _hex_grid: HexGridNode


func init(grid: HexGridNode) -> void:
	_hex_grid = grid


func show_preview(directions: Array[int]) -> void:
	_directions = directions
	visible = true


func hide_preview() -> void:
	_directions = []
	visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if _directions.is_empty():
		return
	_pulse_timer += delta
	queue_redraw()


func _draw() -> void:
	if _directions.is_empty() or _hex_grid == null:
		return

	var pulse := (sin(_pulse_timer * PULSE_SPEED) + 1.0) / 2.0
	var color := Color(ARROW_COLOR.r, ARROW_COLOR.g, ARROW_COLOR.b, 0.5 + pulse * 0.4)
	var center := _hex_grid.hex_grid_to_pixel(Vector2i.ZERO)

	for dir in _directions:
		var dir_vec := HexGrid.DIRECTIONS[dir]
		var edge_hex := Vector2i(dir_vec.x * (_hex_grid.grid_radius + 2), dir_vec.y * (_hex_grid.grid_radius + 2))
		var edge_px := _hex_grid.hex_grid_to_pixel(edge_hex)

		var toward_center := (center - edge_px).normalized()
		var arrow_start := edge_px
		var arrow_end := edge_px + toward_center * 80.0

		# Shaft
		draw_line(arrow_start, arrow_end, color, 4.0)

		# Arrowhead
		var perp := Vector2(-toward_center.y, toward_center.x)
		draw_colored_polygon(PackedVector2Array([
			arrow_end + toward_center * 20.0,
			arrow_end + perp * 14.0,
			arrow_end - perp * 14.0,
		]), color)

		# Direction label
		draw_string(ThemeDB.fallback_font, arrow_start - toward_center * 20.0,
			HexGrid.DIR_NAMES[dir], HORIZONTAL_ALIGNMENT_CENTER, -1, 22, color)
