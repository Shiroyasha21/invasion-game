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
@export var animal_type: TowerData.AnimalType = TowerData.AnimalType.FROG
@export var can_target_flying: bool = false
@export var projectile_scene: PackedScene

const DAMAGE_FLASH_DURATION := 0.15

var tower_id: String = ""
var rare_attachment: RareAttachmentData = null
var current_hp: float
var occupied_hex: Vector2i = Vector2i.ZERO
var _fire_timer: float = 1.0
var _target: EnemyBase = null
var _damage_flash: float = 0.0


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
	animal_type = data.animal_type
	can_target_flying = data.can_target_flying


func _ready() -> void:
	current_hp = max_hp
	_fire_timer = _effective_fire_interval()
	SkillTree.shield_changed.connect(_on_shield_changed)


func _on_shield_changed(_active: bool) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if _damage_flash > 0.0:
		_damage_flash = maxf(_damage_flash - delta, 0.0)
		queue_redraw()

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
	if SkillTree.shield_active:
		return
	current_hp -= amount
	_damage_flash = DAMAGE_FLASH_DURATION
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
			if node.is_flying and not can_target_flying:
				continue
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

	match animal_type:
		TowerData.AnimalType.OWL:
			SFX.play_owl_screech()
		TowerData.AnimalType.GRENADIER:
			SFX.play_grenade_launch()
		_:
			if projectile_is_streak:
				SFX.play_laser()
			elif splash_radius > 0.0:
				SFX.play_splash()
			else:
				SFX.play_shoot()


func _draw() -> void:
	var hp_ratio := current_hp / max_hp

	# The node itself rotates to face its target, so counter-rotate the
	# shadow draw to keep it pointing in a consistent world-down direction.
	draw_set_transform(Vector2(0.0, body_radius * 0.4).rotated(-rotation), -rotation, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, body_radius + 8.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var color := body_color.lerp(Color(0.8, 0.2, 0.1), 1.0 - hp_ratio)
	color = color.lerp(Color.WHITE, _damage_flash / DAMAGE_FLASH_DURATION)

	match animal_type:
		TowerData.AnimalType.BEAR:
			_draw_bear(color)
		TowerData.AnimalType.MONKEY:
			_draw_monkey(color)
		TowerData.AnimalType.OWL:
			_draw_owl(color)
		TowerData.AnimalType.GRENADIER:
			_draw_grenadier(color)
		_:
			_draw_frog(color)

	if rare_attachment != null:
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0, TAU, 32, Color(1.0, 0.85, 0.1, 0.9), 3.0)

	if SkillTree.shield_active:
		draw_arc(Vector2.ZERO, body_radius + 12.0, 0, TAU, 32, Color(0.3, 0.7, 1.0, 0.7), 4.0)


# Squat, round, tongue-flicks at its target.
func _draw_frog(color: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.1, 0.85))
	draw_circle(Vector2.ZERO, body_radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for side in [-1.0, 1.0]:
		var eye_pos := Vector2(body_radius * 0.2, side * body_radius * 0.55)
		draw_circle(eye_pos, body_radius * 0.26, Color(0.95, 0.98, 0.9))
		draw_circle(eye_pos, body_radius * 0.13, Color(0.05, 0.05, 0.05))
	draw_line(Vector2.ZERO, Vector2(barrel_length, 0), Color(0.85, 0.2, 0.3), 3.0)


# Bulky, chunky, slams its splash damage down.
func _draw_bear(color: Color) -> void:
	draw_circle(Vector2.ZERO, body_radius, color)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(-body_radius * 0.5, side * body_radius * 0.65), body_radius * 0.3, color.darkened(0.2))
	draw_circle(Vector2(body_radius * 0.6, 0), body_radius * 0.34, color.darkened(0.15))
	draw_circle(Vector2(body_radius * 0.85, 0), body_radius * 0.1, Color(0.08, 0.08, 0.08))


# Perched, long-armed, hurls a rock at its target.
func _draw_monkey(color: Color) -> void:
	draw_circle(Vector2.ZERO, body_radius, color)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(-body_radius * 0.15, side * body_radius * 0.9), body_radius * 0.28, color.lightened(0.1))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(body_radius * 0.4, side * body_radius * 0.32), body_radius * 0.16, Color(0.05, 0.05, 0.05))
	var arm_end := Vector2(barrel_length, 0)
	draw_line(Vector2.ZERO, arm_end, color.darkened(0.15), 5.0)
	draw_circle(arm_end, body_radius * 0.24, Color(0.55, 0.5, 0.45))


# Perched and watchful, swivels its head and dives on flying threats.
func _draw_owl(color: Color) -> void:
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(0, side * body_radius * 0.25), 0.0, Vector2(0.55, 1.3))
		draw_circle(Vector2(side * body_radius * 0.75, 0), body_radius * 0.65, color.darkened(0.15))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_circle(Vector2.ZERO, body_radius, color)
	for side in [-1.0, 1.0]:
		var eye_pos := Vector2(body_radius * 0.3, side * body_radius * 0.38)
		draw_circle(eye_pos, body_radius * 0.3, Color(1.0, 0.95, 0.8))
		draw_circle(eye_pos, body_radius * 0.15, Color(0.05, 0.05, 0.05))
	var beak := PackedVector2Array([
		Vector2(body_radius * 0.85, -body_radius * 0.12),
		Vector2(body_radius * 1.25, 0),
		Vector2(body_radius * 0.85, body_radius * 0.12),
	])
	draw_colored_polygon(beak, Color(0.9, 0.6, 0.1))


# A soldier who wandered into the wrong forest. Lobs grenades.
func _draw_grenadier(color: Color) -> void:
	var body_pts := PackedVector2Array([
		Vector2(-body_radius * 0.5, -body_radius * 0.65), Vector2(body_radius * 0.5, -body_radius * 0.65),
		Vector2(body_radius * 0.5, body_radius * 0.75), Vector2(-body_radius * 0.5, body_radius * 0.75),
	])
	draw_colored_polygon(body_pts, color)
	draw_circle(Vector2(0, -body_radius * 0.95), body_radius * 0.42, Color(0.85, 0.7, 0.55))
	draw_arc(Vector2(0, -body_radius * 1.0), body_radius * 0.48, PI, TAU, 16, Color(0.25, 0.35, 0.2), 6.0)
	draw_line(Vector2.ZERO, Vector2(barrel_length, 0), Color(0.2, 0.2, 0.2), 8.0)
	draw_circle(Vector2(barrel_length, 0), body_radius * 0.22, Color(0.25, 0.5, 0.2))
