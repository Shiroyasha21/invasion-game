extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 50.0
@export var max_health: float = 30.0
@export var coin_scene: PackedScene
@export var damage_to_center: float = 10.0

@export var attack_damage: float = 8.0
@export var attack_speed: float = 1.0

var current_health: float
var target_position: Vector2 = Vector2.ZERO
var center_piece: CenterPiece
var _blocked_by: TowerBase = null
var _attack_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.2, 0.2))


func init(spawn_pixel: Vector2, target_pos: Vector2, cp: CenterPiece = null) -> void:
	center_piece = cp
	global_position = spawn_pixel
	target_position = target_pos


func _process(delta: float) -> void:
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

	var to_target := target_position - global_position
	if to_target.length() < 8.0:
		_on_reached_center()
		return

	velocity = to_target.normalized() * move_speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is TowerBase:
			_blocked_by = collider
			_attack_timer = 0.0
			break


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
