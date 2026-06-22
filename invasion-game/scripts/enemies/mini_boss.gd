extends EnemyBase
class_name MiniBoss

signal tower_displaced(tower: TowerBase)

const BULLDOZE_COOLDOWN := 0.4
const BULLDOZE_DAMAGE_FRACTION := 0.3  # crashing through costs it less than a focused hit

@export var projectile_scene: PackedScene

var boss_data: MiniBossData
var attack_pattern: int = MiniBossData.AttackPattern.SLAM
var movement_behavior: int = MiniBossData.MovementBehavior.BULLDOZE
var boss_attack_range: float = 140.0
var attack_interval: float = 2.0
var splash_radius: float = 80.0

var _boss_attack_timer: float = 0.0
var _bulldoze_timer: float = 0.0
var _sieging: bool = false
var _sweep_point: Vector2 = Vector2.ZERO
var _reached_sweep: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("mini_bosses")
	if movement_behavior == MiniBossData.MovementBehavior.FLYER:
		collision_mask = 0
		is_flying = true


# elapsed_minutes is the run time at the moment of spawn — stats are
# snapshotted once here and never recalculated while the boss is alive.
func setup_from_data(data: MiniBossData, elapsed_minutes: float) -> void:
	boss_data = data
	var hp_mult := 1.0 + data.hp_growth_rate * elapsed_minutes
	var dmg_mult := 1.0 + data.damage_growth_rate * elapsed_minutes
	max_health = data.base_hp * hp_mult
	current_health = max_health
	move_speed = data.base_speed
	attack_pattern = data.attack_pattern
	movement_behavior = data.movement_behavior
	boss_attack_range = data.attack_range
	attack_interval = data.attack_interval
	splash_radius = data.splash_radius
	attack_damage = data.base_damage * dmg_mult
	_boss_attack_timer = attack_interval

	if movement_behavior == MiniBossData.MovementBehavior.SWEEPER:
		var offset := global_position - target_position
		var angle := deg_to_rad(data.sweep_angle_deg) * (1.0 if randf() < 0.5 else -1.0)
		_sweep_point = target_position + offset.rotated(angle)
	if movement_behavior == MiniBossData.MovementBehavior.FLYER:
		collision_mask = 0
		is_flying = true


# Overrides EnemyBase entirely — bosses don't get stuck single-target
# fighting a blocking tower, and don't die from touching the centerpiece.
func _process(delta: float) -> void:
	rotation = (target_position - global_position).angle()

	_boss_attack_timer -= delta
	if _boss_attack_timer <= 0.0:
		_boss_attack_timer = attack_interval
		if _sieging:
			_siege_center()
		else:
			_try_ranged_attack()

	if _sieging:
		velocity = Vector2.ZERO
		return

	var sweeping := movement_behavior == MiniBossData.MovementBehavior.SWEEPER and not _reached_sweep
	var current_target := _sweep_point if sweeping else target_position
	var to_target := current_target - global_position

	if sweeping:
		if to_target.length() < 24.0:
			_reached_sweep = true
	elif to_target.length() < 12.0:
		_sieging = true
		return

	velocity = to_target.normalized() * move_speed
	move_and_slide()

	if movement_behavior != MiniBossData.MovementBehavior.FLYER:
		_bulldoze_timer -= delta
		for i in get_slide_collision_count():
			var collider := get_slide_collision(i).get_collider()
			if collider is TowerBase:
				_on_tower_contact(collider)


func _on_tower_contact(collider: TowerBase) -> void:
	if _bulldoze_timer > 0.0:
		return
	_bulldoze_timer = BULLDOZE_COOLDOWN
	if movement_behavior == MiniBossData.MovementBehavior.DISPLACER:
		emit_signal("tower_displaced", collider)
	else:
		_bulldoze_damage(collider)


# Crashes through towers in its path instead of stopping to trade hits.
func _bulldoze_damage(collider: TowerBase) -> void:
	var dmg := attack_damage * BULLDOZE_DAMAGE_FRACTION
	collider.take_damage(dmg)
	if splash_radius > 0.0:
		for node in get_tree().get_nodes_in_group("towers"):
			if node != collider and node is TowerBase and node.global_position.distance_to(collider.global_position) <= splash_radius:
				node.take_damage(dmg)


func _siege_center() -> void:
	if center_piece == null:
		return
	var multiplier := boss_data.center_damage_multiplier if boss_data != null else 3.0
	center_piece.take_damage(attack_damage * multiplier)


func _try_ranged_attack() -> void:
	var nearest := _find_nearest_tower()
	if nearest == null:
		return
	if global_position.distance_to(nearest.global_position) > boss_attack_range:
		return
	match attack_pattern:
		MiniBossData.AttackPattern.RANGED:
			_fire_projectile(nearest)
		MiniBossData.AttackPattern.SLAM:
			_area_slam()


func _find_nearest_tower() -> TowerBase:
	var nearest: TowerBase = null
	var nearest_dist := boss_attack_range
	for node in get_tree().get_nodes_in_group("towers"):
		if node is TowerBase:
			var d := global_position.distance_to(node.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = node
	return nearest


func _fire_projectile(target: TowerBase) -> void:
	if projectile_scene == null:
		return
	var proj: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.init(target, attack_damage)


func _area_slam() -> void:
	for node in get_tree().get_nodes_in_group("towers"):
		if node is TowerBase and global_position.distance_to(node.global_position) <= splash_radius:
			node.take_damage(attack_damage)


func _draw() -> void:
	var scale_factor := boss_data.visual_scale if boss_data != null else 1.8
	var radius := 20.0 * scale_factor
	var is_flyer := movement_behavior == MiniBossData.MovementBehavior.FLYER

	var shadow_offset := Vector2(5.0, radius * 0.4) if not is_flyer else Vector2(8.0, radius * 0.7)
	var shadow_scale := 0.55 if not is_flyer else 0.4
	draw_set_transform(shadow_offset.rotated(-rotation), -rotation, Vector2(1.0, shadow_scale))
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.0, 0.0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	match movement_behavior:
		MiniBossData.MovementBehavior.SWEEPER:
			_draw_stag_beetle(radius)
		MiniBossData.MovementBehavior.DISPLACER:
			_draw_goliath_beetle(radius)
		MiniBossData.MovementBehavior.FLYER:
			_draw_hornet(radius)
		_:
			if attack_pattern == MiniBossData.AttackPattern.RANGED:
				_draw_mantis(radius)
			else:
				_draw_rhino_beetle(radius)


func _draw_body(radius: float, color: Color) -> void:
	draw_set_transform(Vector2(-radius * 0.2, 0), 0.0, Vector2(1.25, 0.85))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(radius * 0.75, 0), radius * 0.6, color.darkened(0.12))
	draw_arc(Vector2(-radius * 0.2, 0), radius * 1.25, 0, TAU, 24, color.darkened(0.4), 3.0)


func _draw_boss_legs(radius: float, color: Color, count: int = 4) -> void:
	for side in [-1.0, 1.0]:
		for i in count:
			var lx := -radius * 0.6 + i * radius * 0.4
			draw_line(Vector2(lx, side * radius * 0.6), Vector2(lx + side * radius * 0.2, side * radius * 1.3), color, 3.0)


# Brute — low and horned, built for charging through whatever's ahead.
func _draw_rhino_beetle(radius: float) -> void:
	var color := Color(0.35, 0.22, 0.1)
	_draw_body(radius, color)
	_draw_boss_legs(radius, color.darkened(0.5))
	var horn := PackedVector2Array([
		Vector2(radius * 1.1, -radius * 0.15), Vector2(radius * 1.9, 0), Vector2(radius * 1.1, radius * 0.15),
	])
	draw_colored_polygon(horn, color.darkened(0.3))


# Marksman — raised raptorial arms, picks towers off from range.
func _draw_mantis(radius: float) -> void:
	var color := Color(0.3, 0.55, 0.2)
	_draw_body(radius, color)
	_draw_boss_legs(radius, color.darkened(0.45), 3)
	for side in [-1.0, 1.0]:
		var elbow := Vector2(radius * 0.5, side * radius * 0.5)
		var tip := elbow + Vector2(radius * 0.7, side * radius * 0.1)
		draw_line(Vector2(radius * 0.2, side * radius * 0.2), elbow, color.darkened(0.3), 4.0)
		draw_line(elbow, tip, color.darkened(0.3), 4.0)


# Stag Beetle — big curved mandibles, sweeps the perimeter before committing.
func _draw_stag_beetle(radius: float) -> void:
	var color := Color(0.45, 0.18, 0.12)
	_draw_body(radius, color)
	_draw_boss_legs(radius, color.darkened(0.5))
	for side in [-1.0, 1.0]:
		var base := Vector2(radius * 1.1, side * radius * 0.25)
		var mid := base + Vector2(radius * 0.9, side * radius * 0.55)
		var tip := mid + Vector2(radius * 0.2, side * -0.3)
		draw_line(base, mid, color.darkened(0.55), 6.0)
		draw_line(mid, tip, color.darkened(0.55), 6.0)


# Goliath Beetle — broad armored shell built for shoving towers aside.
func _draw_goliath_beetle(radius: float) -> void:
	var color := Color(0.55, 0.42, 0.18)
	draw_set_transform(Vector2(-radius * 0.1, 0), 0.0, Vector2(1.2, 1.0))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(radius * 0.7, 0), radius * 0.45, color.darkened(0.15))
	draw_arc(Vector2(-radius * 0.1, 0), radius * 1.2, 0, TAU, 24, color.darkened(0.4), 4.0)
	draw_line(Vector2(-radius * 1.0, 0), Vector2(radius * 0.6, 0), color.darkened(0.5), 3.0)
	_draw_boss_legs(radius, color.darkened(0.5))


# Hornet — narrow striped flier, the only boss towers can't physically block.
func _draw_hornet(radius: float) -> void:
	var color := Color(0.9, 0.75, 0.1)
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(-radius * 0.2, side * radius * 0.95), 0.0, Vector2(1.8, 0.75))
		draw_circle(Vector2.ZERO, radius * 0.6, Color(1.0, 1.0, 1.0, 0.45))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2(-radius * 0.2, 0), 0.0, Vector2(1.5, 0.6))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		var lx := -radius * 0.7 + i * radius * 0.5
		draw_line(Vector2(lx, -radius * 0.45), Vector2(lx, radius * 0.45), Color(0.1, 0.08, 0.02), 3.0)
	draw_circle(Vector2(radius * 0.85, 0), radius * 0.45, color.darkened(0.12))
