extends Node2D
class_name Projectile

var _target: EnemyBase
var _damage: float
var _speed: float = 400.0


func init(target: EnemyBase, damage: float) -> void:
	_target = target
	_damage = damage


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return

	var dir := (_target.global_position - global_position).normalized()
	global_position += dir * _speed * delta

	if global_position.distance_to(_target.global_position) < 10.0:
		_target.take_damage(_damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.2))
