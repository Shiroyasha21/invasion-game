extends StaticBody2D
class_name TowerBase

signal destroyed(hex: Vector2i)

@export var attack_range: float = 200.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var max_hp: float = 50.0
@export var cost: int = 10
@export var projectile_scene: PackedScene

var current_hp: float
var occupied_hex: Vector2i = Vector2i.ZERO
var _fire_timer: float = 1.0
var _target: EnemyBase = null


func _ready() -> void:
	current_hp = max_hp
	_fire_timer = 1.0 / attack_speed


func _process(delta: float) -> void:
	_target = _find_nearest_enemy()
	if _target == null:
		return

	var dir := (_target.global_position - global_position).normalized()
	rotation = atan2(dir.y, dir.x)

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = 1.0 / attack_speed


func take_damage(amount: float) -> void:
	current_hp -= amount
	queue_redraw()
	if current_hp <= 0.0:
		emit_signal("destroyed", occupied_hex)
		queue_free()


func _find_nearest_enemy() -> EnemyBase:
	var nearest: EnemyBase = null
	var nearest_dist := attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyBase:
			var d := global_position.distance_to(node.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = node
	return nearest


func _fire() -> void:
	if projectile_scene == null or _target == null:
		return
	var proj: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.init(_target, attack_damage)


func _draw() -> void:
	var hp_ratio := current_hp / max_hp
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * i - 30.0)
		pts.append(Vector2(cos(angle), sin(angle)) * 28.0)

	var body_color := Color(0.4, 0.5, 0.6).lerp(Color(0.8, 0.2, 0.1), 1.0 - hp_ratio)
	draw_colored_polygon(pts, body_color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.7, 0.8, 1.0), 2.0)
	draw_line(Vector2.ZERO, Vector2(30, 0), Color(0.8, 0.9, 1.0), 4.0)

	# HP bar
	var bar_w := 50.0
	draw_rect(Rect2(Vector2(-bar_w / 2, -42), Vector2(bar_w, 7)), Color(0.2, 0.1, 0.1))
	draw_rect(Rect2(Vector2(-bar_w / 2, -42), Vector2(bar_w * hp_ratio, 7)), Color(0.2, 0.85, 0.3))
