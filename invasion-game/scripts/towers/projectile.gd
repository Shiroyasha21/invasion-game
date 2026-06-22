extends Node2D
class_name Projectile

var _target: Node2D
var _damage: float
var _speed: float = 400.0
var _splash_radius: float = 0.0
var _color: Color = Color(1.0, 0.9, 0.2)
var _radius: float = 6.0
var _is_streak: bool = false


func init(target: Node2D, damage: float, splash_radius: float = 0.0, color: Color = Color(1.0, 0.9, 0.2), radius: float = 6.0, speed: float = 400.0, is_streak: bool = false) -> void:
	_target = target
	_damage = damage
	_splash_radius = splash_radius
	_color = color
	_radius = radius
	_speed = speed
	_is_streak = is_streak


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return

	var dir := (_target.global_position - global_position).normalized()
	global_position += dir * _speed * delta
	rotation = dir.angle()

	if global_position.distance_to(_target.global_position) < 10.0:
		_hit()
		queue_free()


func _hit() -> void:
	if _target.has_method("take_damage"):
		_target.take_damage(_damage)
	if _splash_radius > 0.0:
		for node in get_tree().get_nodes_in_group("enemies"):
			if node != _target and node is Node2D and node.global_position.distance_to(global_position) <= _splash_radius:
				node.take_damage(_damage)
		SFX.play_explosion()
	else:
		SFX.play_hit()


func _draw() -> void:
	if _is_streak:
		draw_line(Vector2(-_radius * 3.0, 0), Vector2(_radius * 1.0, 0), _color, 3.0)
	else:
		draw_circle(Vector2.ZERO, _radius, _color)
