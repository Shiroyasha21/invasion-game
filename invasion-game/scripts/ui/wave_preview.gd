extends Node
class_name WavePreview

var _hex_grid: HexGridNode


func init(grid: HexGridNode) -> void:
	_hex_grid = grid


func show_preview(spawn_hexes: Array[Vector2i]) -> void:
	var hexes: Array[Vector2i] = []
	for spawn in spawn_hexes:
		for hex in _hex_path(spawn, Vector2i.ZERO):
			if hex not in hexes:
				hexes.append(hex)
	_hex_grid.set_highlights(hexes)


func hide_preview() -> void:
	_hex_grid.clear_highlights()


func _hex_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open: Array = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: HexGrid.distance(start, goal)}

	while open.size() > 0:
		var current: Vector2i = open[0]
		for node in open:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node
		if current == goal:
			var path: Array[Vector2i] = []
			var node := current
			while came_from.has(node):
				path.push_front(node)
				node = came_from[node]
			return path
		open.erase(current)
		for neighbor in HexGrid.neighbors(current):
			var tentative_g: int = g_score.get(current, INF) + 1
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + HexGrid.distance(neighbor, goal)
				if neighbor not in open:
					open.append(neighbor)
	return []
