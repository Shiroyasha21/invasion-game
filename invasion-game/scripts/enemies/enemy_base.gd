extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var max_health: float = 30.0
@export var coin_scene: PackedScene
@export var damage_to_center: float = 10.0

var current_health: float
var path: Array[Vector2] = []
var path_index: int = 0
var hex_grid: HexGridNode
var center_piece: CenterPiece


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.2, 0.2))


func init_with_path(grid: HexGridNode, spawn_pixel: Vector2, precomputed_path: Array[Vector2], cp: CenterPiece = null) -> void:
	hex_grid = grid
	center_piece = cp
	global_position = spawn_pixel
	path = precomputed_path
	path_index = 0


func _process(_delta: float) -> void:
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
	if center_piece != null:
		center_piece.take_damage(damage_to_center)
	emit_signal("reached_center")
	queue_free()


signal died(position: Vector2)
signal reached_center
