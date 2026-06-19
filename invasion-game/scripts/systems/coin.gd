extends Node2D
class_name Coin

var value: int = 1
var essence_value: int = 0
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
			GameState.add_coins(value)
			if essence_value > 0:
				GameState.add_essence(essence_value)
			SFX.play_coin()
			queue_free()
	else:
		_bob_timer += delta
		global_position.y = _origin.y + sin(_bob_timer * BOB_SPEED) * BOB_AMOUNT
	queue_redraw()


func suck_toward(target: Vector2) -> void:
	_sucked = true
	_suck_target = target


func _draw() -> void:
	var scale_factor := 1.0 + clampf(float(value - 1) / 20.0, 0.0, 1.2)
	var outer := Color(1.0, 0.85, 0.1)
	var inner := Color(1.0, 0.95, 0.4)
	if essence_value > 0:
		outer = outer.lerp(Color(0.3, 1.0, 0.5), 0.5)
		inner = inner.lerp(Color(0.6, 1.0, 0.7), 0.5)
	draw_circle(Vector2.ZERO, 10.0 * scale_factor, outer)
	draw_circle(Vector2.ZERO, 7.0 * scale_factor, inner)
