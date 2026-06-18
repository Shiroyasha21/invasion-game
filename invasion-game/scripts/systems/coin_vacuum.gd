extends Node2D
class_name CoinVacuum

const RADIUS := 100.0

var _active: bool = false
var _finger_pos: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		# Reserve single tap for tower placement — vacuum needs drag
		if not event.pressed:
			_active = false
			queue_redraw()
	elif event is InputEventScreenDrag:
		_active = true
		_finger_pos = get_canvas_transform().affine_inverse() * event.position
		queue_redraw()
		_pull_coins()
	# Mouse fallback for desktop testing
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_active = event.pressed
			if not _active:
				queue_redraw()
	elif event is InputEventMouseMotion and _active:
		_finger_pos = get_canvas_transform().affine_inverse() * event.position
		queue_redraw()
		_pull_coins()


func _pull_coins() -> void:
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin is Coin:
			if coin.global_position.distance_to(_finger_pos) <= RADIUS:
				coin.suck_toward(_finger_pos)


func _draw() -> void:
	if not _active:
		return
	draw_circle(_finger_pos, RADIUS, Color(1.0, 1.0, 1.0, 0.08))
	draw_arc(_finger_pos, RADIUS, 0, TAU, 48, Color(1.0, 0.95, 0.3, 0.5), 2.0)
