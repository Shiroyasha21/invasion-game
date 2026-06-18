extends Node2D
class_name Coin

var _bob_timer: float = 0.0
var _origin: Vector2
var _sucked: bool = false
var _suck_target: Vector2

const BOB_SPEED := 2.5
const BOB_AMOUNT := 6.0
const SUCK_SPEED := 500.0


func set_origin(pos: Vector2) -> void:
	_origin = pos


func _process(delta: float) -> void:
	if _sucked:
		global_position = global_position.move_toward(_suck_target, SUCK_SPEED * delta)
		if global_position.distance_to(_suck_target) < 8.0:
			GameState.add_coins(1)
			queue_free()
	else:
		_bob_timer += delta
		global_position.y = _origin.y + sin(_bob_timer * BOB_SPEED) * BOB_AMOUNT
	queue_redraw()


func suck_toward(target: Vector2) -> void:
	_sucked = true
	_suck_target = target


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.95, 0.4))
