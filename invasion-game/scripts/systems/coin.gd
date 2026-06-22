extends Node2D
class_name Coin

var value: int = 1
var essence_value: int = 0
var is_chest: bool = false  # true = Essence pickup, drawn as a chest instead of a coin
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
			if value > 0:
				GameState.add_coins(value)
				SFX.play_coin()
			if essence_value > 0:
				GameState.add_essence(essence_value)
				SFX.play_chest_open()
			queue_free()
	else:
		_bob_timer += delta
		global_position.y = _origin.y + sin(_bob_timer * BOB_SPEED) * BOB_AMOUNT
	queue_redraw()


func suck_toward(target: Vector2) -> void:
	_sucked = true
	_suck_target = target


func _draw() -> void:
	if not _sucked:
		_draw_shadow()
	if is_chest:
		_draw_chest()
	else:
		_draw_coin()


func _draw_shadow() -> void:
	# Keep the shadow pinned to the ground line while the pickup bobs above it.
	var ground_y := _origin.y - global_position.y
	draw_set_transform(Vector2(2.0, ground_y), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 10.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_coin() -> void:
	var scale_factor := 1.0 + clampf(float(value - 1) / 20.0, 0.0, 1.2)
	draw_circle(Vector2.ZERO, 10.0 * scale_factor, Color(0.7, 0.52, 0.05))
	draw_circle(Vector2.ZERO, 8.5 * scale_factor, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2.ZERO, 5.5 * scale_factor, Color(1.0, 0.95, 0.55))
	draw_line(Vector2(-3.5 * scale_factor, 0), Vector2(3.5 * scale_factor, 0), Color(0.75, 0.55, 0.08), 1.5)


func _draw_chest() -> void:
	var s := 1.0 + clampf(float(essence_value - 1) / 25.0, 0.0, 1.0)
	var w := 18.0 * s
	var h := 12.0 * s
	draw_rect(Rect2(Vector2(-w / 2.0, -h / 2.0), Vector2(w, h)), Color(0.42, 0.27, 0.13))
	draw_rect(Rect2(Vector2(-w / 2.0, -h / 2.0 - 4.0 * s), Vector2(w, 4.0 * s)), Color(0.52, 0.34, 0.16))
	draw_rect(Rect2(Vector2(-1.5 * s, -h * 0.15), Vector2(3.0 * s, h * 0.45)), Color(1.0, 0.85, 0.2))
	draw_rect(Rect2(Vector2(-w / 2.0, -h / 2.0 - 4.0 * s), Vector2(w, h + 4.0 * s)), Color(0.2, 0.12, 0.05), false, 1.5)
