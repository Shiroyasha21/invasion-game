extends StaticBody2D
class_name TowerBase

signal destroyed(hex: Vector2i)

@export var attack_range: float = 200.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var max_hp: float = 50.0
@export var cost: int = 10
@export var splash_radius: float = 0.0
@export var body_color: Color = Color(0.4, 0.5, 0.6)
@export var body_radius: float = 28.0
@export var barrel_length: float = 30.0
@export var projectile_color: Color = Color(1.0, 0.9, 0.2)
@export var projectile_radius: float = 6.0
@export var projectile_speed: float = 400.0
@export var projectile_is_streak: bool = false
@export var target_mode: TowerData.TargetMode = TowerData.TargetMode.NEAREST
@export var projectile_scene: PackedScene

var tower_id: String = ""
var rare_attachment: RareAttachmentData = null
var current_hp: float
var occupied_hex: Vector2i = Vector2i.ZERO
var _fire_timer: float = 1.0
var _target: EnemyBase = null


func setup(data: TowerData) -> void:
	tower_id = data.id
	attack_range = data.attack_range
	attack_damage = data.attack_damage
	attack_speed = data.attack_speed
	max_hp = data.max_hp
	cost = data.cost
	splash_radius = data.splash_radius
	body_color = data.body_color
	body_radius = data.body_radius
	barrel_length = data.barrel_length
	projectile_color = data.projectile_color
	projectile_radius = data.projectile_radius
	projectile_speed = data.projectile_speed
	projectile_is_streak = data.projectile_is_streak
	target_mode = data.target_mode


func _ready() -> void:
	current_hp = max_hp
	_fire_timer = _effective_fire_interval()


func _process(delta: float) -> void:
	_target = _find_target()
	if _target == null:
		return

	var dir := (_target.global_position - global_position).normalized()
	rotation = atan2(dir.y, dir.x)

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = _effective_fire_interval()


func take_damage(amount: float) -> void:
	current_hp -= amount
	queue_redraw()
	if current_hp <= 0.0:
		SFX.play_tower_destroyed()
		emit_signal("destroyed", occupied_hex)
		queue_free()


# Live multipliers from BuildState (global upgrades) and this tower's own
# rare attachment, if any. Computed on the fly so upgrades picked mid-run
# instantly affect towers already on the field.
func _effective_range() -> float:
	var r := attack_range * BuildState.range_multiplier(tower_id)
	if rare_attachment != null:
		r *= rare_attachment.range_multiplier
	return r


func _effective_damage() -> float:
	var d := attack_damage * BuildState.damage_multiplier(tower_id)
	if rare_attachment != null:
		d *= rare_attachment.damage_multiplier
	return d


func _effective_fire_interval() -> float:
	return (1.0 / attack_speed) / BuildState.fire_rate_multiplier(tower_id)


func _effective_splash() -> float:
	return splash_radius * BuildState.splash_multiplier(tower_id)


func _find_target() -> EnemyBase:
	var range_now := _effective_range()
	var best: EnemyBase = null
	var best_dist := -1.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyBase:
			var d := global_position.distance_to(node.global_position)
			if d > range_now:
				continue
			var is_better := best == null
			if not is_better:
				is_better = d > best_dist if target_mode == TowerData.TargetMode.FARTHEST else d < best_dist
			if is_better:
				best = node
				best_dist = d
	return best


func _fire() -> void:
	if projectile_scene == null or _target == null:
		return
	var proj: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.init(_target, _effective_damage(), _effective_splash(), projectile_color, projectile_radius, projectile_speed, projectile_is_streak)

	if projectile_is_streak:
		SFX.play_laser()
	elif splash_radius > 0.0:
		SFX.play_splash()
	else:
		SFX.play_shoot()


func _draw() -> void:
	var hp_ratio := current_hp / max_hp
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * i - 30.0)
		pts.append(Vector2(cos(angle), sin(angle)) * body_radius)

	var color := body_color.lerp(Color(0.8, 0.2, 0.1), 1.0 - hp_ratio)
	draw_colored_polygon(pts, color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.7, 0.8, 1.0), 2.0)
	draw_line(Vector2.ZERO, Vector2(barrel_length, 0), Color(0.8, 0.9, 1.0), 4.0)

	if rare_attachment != null:
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0, TAU, 32, Color(1.0, 0.85, 0.1, 0.9), 3.0)

	# HP bar
	var bar_w := 50.0
	var bar_y := -body_radius - 14.0
	draw_rect(Rect2(Vector2(-bar_w / 2, bar_y), Vector2(bar_w, 7)), Color(0.2, 0.1, 0.1))
	draw_rect(Rect2(Vector2(-bar_w / 2, bar_y), Vector2(bar_w * hp_ratio, 7)), Color(0.2, 0.85, 0.3))
