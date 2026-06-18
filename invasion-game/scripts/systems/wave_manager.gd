extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0

var hex_grid: HexGridNode
var coin_scene: PackedScene
var center_piece: CenterPiece
var wave_preview: WavePreview
var current_wave: int = 0
var enemies_remaining: int = 0
var _spawn_timer: float = 0.0
var _spawn_queue: Array[Dictionary] = []
var _precomputed_paths: Dictionary = {}  # dir -> PathData


func init(grid: HexGridNode) -> void:
	hex_grid = grid


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	GameState.set_wave(wave_number)

	# Pre-compute one path per active direction
	var dirs := _active_directions(wave_number)
	_precomputed_paths.clear()
	var spawn_hexes: Array[Vector2i] = []
	for dir in dirs:
		var spawn_hex := _spawn_hex_for_direction(dir)
		spawn_hexes.append(spawn_hex)
		var points := _compute_pixel_path(spawn_hex, Vector2i.ZERO)
		_precomputed_paths[dir] = PathData.make(PathData.Type.STRAIGHT, spawn_hex, points)

	if wave_preview != null:
		wave_preview.show_preview(spawn_hexes)
		await get_tree().create_timer(3.0).timeout
		wave_preview.hide_preview()

	_spawn_queue = _build_spawn_queue(wave_number)
	enemies_remaining = _spawn_queue.size()
	_spawn_timer = 0.0
	emit_signal("wave_started", wave_number)


func _process(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()
		_spawn_timer = spawn_interval


func _build_spawn_queue(wave: int) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	var count := 3 + wave * 2

	# Wave 1-2: North only. 3-4: N+S. 5+: all sides.
	var active_dirs: Array[int] = _active_directions(wave)

	for i in count:
		var dir := active_dirs[i % active_dirs.size()]
		queue.append({"dir": dir})
	return queue


func _active_directions(wave: int) -> Array[int]:
	# Directions: 0=N, 1=NE, 2=SE, 3=S, 4=SW, 5=NW
	if wave <= 2:
		return [0]
	elif wave <= 4:
		return [0, 3]
	elif wave <= 6:
		return [0, 2, 3, 5]
	else:
		return [0, 1, 2, 3, 4, 5]


func _spawn_next() -> void:
	if _spawn_queue.is_empty() or enemy_scene == null:
		return

	var data: Dictionary = _spawn_queue.pop_front()
	var dir: int = data["dir"]
	var path_data: PathData = _precomputed_paths.get(dir, null)
	var spawn_px := path_data.points[0] if path_data and path_data.points.size() > 0 else hex_grid.hex_grid_to_pixel(_spawn_hex_for_direction(dir))

	var enemy: EnemyBase = enemy_scene.instantiate()
	enemy.coin_scene = coin_scene
	get_parent().add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_center.connect(_on_enemy_died.bind(Vector2.ZERO))
	enemy.init_with_path(hex_grid, spawn_px, path_data, center_piece)


func _spawn_hex_for_direction(dir: int) -> Vector2i:
	# Spawn just outside the grid edge in the given direction
	var radius := hex_grid.grid_radius + 1
	var ring := HexGrid.ring(Vector2i.ZERO, radius)
	# Pick the hex in the ring closest to the given axial direction
	var dir_vec: Vector2i = HexGrid.DIRECTIONS[dir]
	var best := ring[0]
	var best_dot := -INF
	for h in ring:
		var dot := float(h.x * dir_vec.x + h.y * dir_vec.y)
		if dot > best_dot:
			best_dot = dot
			best = h
	return best


func _compute_pixel_path(start: Vector2i, goal: Vector2i) -> Array[Vector2]:
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
			var path: Array[Vector2] = []
			var node := current
			while came_from.has(node):
				path.push_front(hex_grid.hex_grid_to_pixel(node))
				node = came_from[node]
			path.push_front(hex_grid.hex_grid_to_pixel(start))
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


func _on_enemy_died(_pos: Vector2) -> void:
	enemies_remaining -= 1
	if enemies_remaining <= 0 and _spawn_queue.is_empty():
		emit_signal("wave_completed", current_wave)
