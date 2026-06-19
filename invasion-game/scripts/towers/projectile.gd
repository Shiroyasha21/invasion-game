extends Node2D
class_name Projectile

var _target: Node2D
var _damage: float
var _speed: float = 400.0
var _splash_radius: float = 0.0


func init(target: Node2D, damage: float, splash_radius: float = 0.0) -> void:
	_target = target
	_damage = damage
	_splash_radius = splash_radius


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return

	var dir := (_target.global_position - global_position).normalized()
	global_position += dir * _speed * delta

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


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.2))
