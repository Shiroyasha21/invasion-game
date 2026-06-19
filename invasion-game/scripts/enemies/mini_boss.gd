extends EnemyBase
class_name MiniBoss

@export var projectile_scene: PackedScene

var boss_data: MiniBossData
var attack_pattern: int = MiniBossData.AttackPattern.SLAM
var boss_attack_range: float = 140.0
var attack_interval: float = 2.0
var splash_radius: float = 80.0

var _boss_attack_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("mini_bosses")


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
	boss_attack_range = data.attack_range
	attack_interval = data.attack_interval
	splash_radius = data.splash_radius
	attack_damage = data.base_damage * dmg_mult
	_boss_attack_timer = attack_interval


func _process(delta: float) -> void:
	super._process(delta)
	_boss_attack_timer -= delta
	if _boss_attack_timer <= 0.0:
		_try_boss_attack()
		_boss_attack_timer = attack_interval


func _try_boss_attack() -> void:
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
	draw_circle(Vector2.ZERO, 20.0 * scale_factor, Color(0.6, 0.1, 0.6))
