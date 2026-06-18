extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var max_health: float = 30.0
@export var coin_scene: PackedScene

var current_health: float
var path: Array[Vector2] = []
var path_index: int = 0
var hex_grid: HexGridNode


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.2, 0.2))


func init(grid: HexGridNode, spawn_pixel: Vector2, target_hex: Vector2i) -> void:
	hex_grid = grid
	global_position = spawn_pixel
	_build_path(target_hex)


func _build_path(target_hex: Vector2i) -> void:
	var start_hex := hex_grid.hex_at_pixel(global_position)
	path = _astar_path(start_hex, target_hex)


func _process(delta: float) -> void:
	if path_index >= path.size():
		_on_reached_center()
		return

	var target_pos := path[path_index]
	var direction := (target_pos - global_position).normalized()
	var distance := global_position.distance_to(target_pos)

	if distance < 4.0:
		path_index += 1
	else:
		velocity = direction * move_speed
		move_and_slide()


func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		_die()


func _die() -> void:
	emit_signal("died", global_position)
	_drop_coin()
	queue_free()


func _drop_coin() -> void:
	if coin_scene == null:
		return
	var coin: Coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position
	coin.add_to_group("coins")
	coin.set_origin(global_position)


func _on_reached_center() -> void:
	emit_signal("reached_center")
	queue_free()


signal died(position: Vector2)
signal reached_center


# A* pathfinding on the hex grid to target
func _astar_path(start: Vector2i, goal: Vector2i) -> Array[Vector2]:
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
			return _reconstruct_path(came_from, current)

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


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var node := current
	while came_from.has(node):
		result.push_front(hex_grid.hex_grid_to_pixel(node))
		node = came_from[node]
	return result
