extends Camera2D
class_name CameraZoom

@export var min_zoom: float = 0.5  # most zoomed-out allowed once fully unlocked
@export var max_zoom: float = 1.5  # most zoomed-in allowed
@export var zoom_step: float = 0.1
@export var pinch_sensitivity: float = 0.01

var _touch_points: Dictionary = {}  # index -> Vector2
var _pinch_start_distance: float = 0.0
var _pinch_start_zoom: float = 1.0
var _zoom_out_floor: float = 1.0  # current lower bound, raised as more grid unlocks


func _ready() -> void:
	zoom = Vector2(_zoom_out_floor, _zoom_out_floor)


func set_unlock_progress(unlocked_radius: int, max_radius: int) -> void:
	var ratio := float(unlocked_radius) / float(max_radius)
	_zoom_out_floor = lerp(max_zoom, min_zoom, ratio)
	# Reveal moment: zoom out to the new floor to show the newly unlocked ring.
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(_zoom_out_floor, _zoom_out_floor), 0.8)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom.x + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom.x - zoom_step)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)
		if _touch_points.size() == 2:
			_pinch_start_distance = _current_touch_distance()
			_pinch_start_zoom = zoom.x
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 2:
			var dist := _current_touch_distance()
			var delta := (dist - _pinch_start_distance) * pinch_sensitivity
			_set_zoom(_pinch_start_zoom + delta)


func _current_touch_distance() -> float:
	var points := _touch_points.values()
	return points[0].distance_to(points[1])


func _set_zoom(value: float) -> void:
	var clamped := clampf(value, _zoom_out_floor, max_zoom)
	zoom = Vector2(clamped, clamped)
