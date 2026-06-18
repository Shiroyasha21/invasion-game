extends Node
class_name WavePreview

var _hex_grid: HexGridNode


func init(grid: HexGridNode) -> void:
	_hex_grid = grid


func show_preview(directions: Array[int]) -> void:
	var hexes: Array[Vector2i] = []
	for dir in directions:
		var dir_vec: Vector2i = HexGrid.DIRECTIONS[dir]
		# Trace the straight corridor from edge to center along this direction axis
		for r in range(1, _hex_grid.grid_radius + 1):
			var hex := Vector2i(dir_vec.x * r, dir_vec.y * r)
			if _hex_grid.is_valid_tile(hex) and hex not in hexes:
				hexes.append(hex)
	_hex_grid.set_highlights(hexes)


func hide_preview() -> void:
	_hex_grid.clear_highlights()
