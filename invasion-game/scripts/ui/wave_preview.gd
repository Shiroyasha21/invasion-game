extends Node
class_name WavePreview

var _hex_grid: HexGridNode


func init(grid: HexGridNode) -> void:
	_hex_grid = grid


func show_preview(directions: Array[int]) -> void:
	var hexes: Array[Vector2i] = []
	for dir in directions:
		# Highlight the outermost ring tiles facing each spawn direction
		var dir_vec: Vector2i = HexGrid.DIRECTIONS[dir]
		for hex in HexGrid.ring(Vector2i.ZERO, _hex_grid.grid_radius):
			var dot := float(hex.x * dir_vec.x + hex.y * dir_vec.y)
			# Include hexes in the top third of the dot product range for that direction
			if dot >= float(_hex_grid.grid_radius) * 0.5:
				hexes.append(hex)
	_hex_grid.set_highlights(hexes)


func hide_preview() -> void:
	_hex_grid.clear_highlights()
