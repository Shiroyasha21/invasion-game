extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var max_health: float = 30.0
@export var coin_scene: PackedScene
@export var damage_to_center: float = 10.0

@export var attack_damage: float = 8.0
@export var attack_speed: float = 1.0

var current_health: float
var path_data: PathData = null
var path_index: int = 0
var hex_grid: HexGridNode
var center_piece: CenterPiece
var _blocked_by: TowerBase = null
var _attack_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.2, 0.2))


func init_with_path(grid: HexGridNode, spawn_pixel: Vector2, pd: PathData, cp: CenterPiece = null) -> void:
	hex_grid = grid
	center_piece = cp
	global_position = spawn_pixel
	path_data = pd
	path_index = 0


func _process(delta: float) -> void:
	if path_data == null or path_index >= path_data.points.size():
		_on_reached_center()
		return

	# Check if blocked by a tower
	if _blocked_by != null:
		if not is_instance_valid(_blocked_by):
			_blocked_by = null
		else:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_blocked_by.take_damage(attack_damage)
				_attack_timer = 1.0 / attack_speed
			velocity = Vector2.ZERO
			move_and_slide()
			return

	var target_pos := path_data.points[path_index]
	var direction := (target_pos - global_position).normalized()
	var distance := global_position.distance_to(target_pos)

	if distance < 4.0:
		path_index += 1
	else:
		# Check if next waypoint hex has a tower
		var next_hex := hex_grid.hex_at_pixel(target_pos)
		var tower := _find_tower_at(next_hex)
		if tower != null:
			_blocked_by = tower
			_attack_timer = 0.0
		else:
			velocity = direction * move_speed
			move_and_slide()


func _find_tower_at(hex: Vector2i) -> TowerBase:
	for node in get_tree().get_nodes_in_group("towers"):
		if node is TowerBase and node.occupied_hex == hex:
			return node
	return null


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
	if center_piece != null:
		center_piece.take_damage(damage_to_center)
	emit_signal("reached_center")
	queue_free()


signal died(position: Vector2)
signal reached_center
