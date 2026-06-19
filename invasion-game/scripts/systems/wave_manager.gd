extends Node
class_name WaveManager

signal run_time_updated(elapsed: float)
signal mini_boss_spawned(boss: MiniBoss)
signal enemy_killed(total_kills: int)

# Direction angles in degrees: N, NE, SE, S, SW, NW (60 degrees apart)
const DIRECTION_ANGLES_DEG := [-90.0, -30.0, 30.0, 90.0, 150.0, -150.0]
const ARC_JITTER_DEG := 25.0
const SPAWN_MARGIN_TILES := 3.0  # extra tiles beyond the rendered grid so enemies appear off-screen

const BASE_SPAWN_INTERVAL := 2.2
const MIN_SPAWN_INTERVAL := 0.4
const DIFFICULTY_GROWTH_PER_MIN := 0.12
const MINI_BOSS_INTERVAL := 90.0
const FIRST_MINI_BOSS_DELAY := 180.0  # give the player time to build up before the first boss
const MINI_BOSS_TELEGRAPH_SECONDS := 3.0  # warning shows this long before the boss actually appears

@export var enemy_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var mini_boss_pool: Array[MiniBossData] = []

var hex_grid: HexGridNode
var camera: CameraZoom
var coin_scene: PackedScene
var projectile_scene: PackedScene
var center_piece: CenterPiece
var wave_preview: WavePreview

var running: bool = false
var elapsed_time: float = 0.0
var kills: int = 0

var _spawn_timer: float = 0.0
var _mini_boss_timer: float = MINI_BOSS_INTERVAL


func init(grid: HexGridNode) -> void:
	hex_grid = grid


func start_run() -> void:
	elapsed_time = 0.0
	kills = 0
	_spawn_timer = BASE_SPAWN_INTERVAL
	_mini_boss_timer = FIRST_MINI_BOSS_DELAY
	running = true


func stop_run() -> void:
	running = false


func _process(delta: float) -> void:
	if not running:
		return

	elapsed_time += delta
	GameState.set_run_time(elapsed_time)
	emit_signal("run_time_updated", elapsed_time)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_pulse()
		_spawn_timer = _current_spawn_interval()

	_mini_boss_timer -= delta
	if _mini_boss_timer <= 0.0:
		_spawn_mini_boss()
		_mini_boss_timer = MINI_BOSS_INTERVAL


func _elapsed_minutes() -> float:
	return elapsed_time / 60.0


func _current_spawn_interval() -> float:
	var t := clampf(_elapsed_minutes() / 8.0, 0.0, 1.0)
	return lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, t)


func _difficulty_multiplier() -> float:
	return 1.0 + _elapsed_minutes() * DIFFICULTY_GROWTH_PER_MIN


func _coin_value_for_time() -> int:
	return mini(1 + int(_elapsed_minutes() / 2.0), 6)


func _active_direction_count() -> int:
	var minutes := _elapsed_minutes()
	if minutes < 1.0:
		return 1
	elif minutes < 3.0:
		return 2
	elif minutes < 5.0:
		return 4
	else:
		return 6


func _sync_size() -> int:
	var minutes := _elapsed_minutes()
	var active := _active_direction_count()
	if minutes < 3.0:
		return 1
	elif minutes < 5.0:
		return mini(2, active)
	else:
		return active


func _spawn_pulse() -> void:
	if enemy_scene == null:
		return
	var active := _active_direction_count()
	var count := _sync_size()
	for _i in count:
		var dir := randi() % active
		_spawn_enemy(dir)


func _spawn_enemy(dir: int) -> void:
	var spawn_pos := _spawn_position(dir, ARC_JITTER_DEG)
	var target_pos := center_piece.global_position if center_piece != null else hex_grid.global_position

	var enemy: EnemyBase = enemy_scene.instantiate()
	var difficulty := _difficulty_multiplier()
	enemy.coin_scene = coin_scene
	enemy.coin_value = _coin_value_for_time()
	enemy.max_health *= difficulty
	enemy.attack_damage *= difficulty
	get_parent().add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_center.connect(_on_enemy_died)
	enemy.init(spawn_pos, target_pos, center_piece)

	if wave_preview != null:
		wave_preview.flash_warning(_warning_position(dir))


func _spawn_mini_boss() -> void:
	if mini_boss_scene == null or mini_boss_pool.is_empty():
		return
	var minutes := _elapsed_minutes()
	var eligible: Array[MiniBossData] = []
	for data in mini_boss_pool:
		if minutes >= data.min_minute and minutes <= data.max_minute:
			eligible.append(data)
	if eligible.is_empty():
		return

	var data: MiniBossData = eligible[randi() % eligible.size()]
	var active := _active_direction_count()
	var dir := _weakest_direction(active)
	var warning_pos := _warning_position(dir)

	if wave_preview != null:
		wave_preview.flash_mini_boss_warning(warning_pos)
	SFX.play_boss_warning()

	await get_tree().create_timer(MINI_BOSS_TELEGRAPH_SECONDS).timeout
	if not running:
		return

	var spawn_pos := _spawn_position(dir, 0.0)
	var target_pos := center_piece.global_position if center_piece != null else hex_grid.global_position

	var boss: MiniBoss = mini_boss_scene.instantiate()
	boss.coin_scene = coin_scene
	boss.projectile_scene = projectile_scene
	get_parent().add_child(boss)
	boss.died.connect(_on_enemy_died)
	boss.reached_center.connect(_on_enemy_died)
	boss.init(spawn_pos, target_pos, center_piece)
	boss.setup_from_data(data, minutes)
	boss.coin_value = data.coin_reward
	boss.essence_value = data.essence_reward
	emit_signal("mini_boss_spawned", boss)


func _spawn_position(dir: int, jitter_deg: float) -> Vector2:
	var jitter := randf_range(-jitter_deg, jitter_deg) if jitter_deg > 0.0 else 0.0
	var angle := deg_to_rad(DIRECTION_ANGLES_DEG[dir] + jitter)
	var tile_radius := (float(hex_grid.max_grid_radius) + SPAWN_MARGIN_TILES) * hex_grid.hex_size
	var spawn_radius := tile_radius
	if camera != null:
		spawn_radius = maxf(tile_radius, camera.max_visible_radius() * 1.15)
	return hex_grid.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius


# Picks the active direction with the fewest nearby towers, so mini-bosses
# hunt the player's weakest-defended side instead of a random one.
func _weakest_direction(active_count: int) -> int:
	var counts: Array[int] = []
	counts.resize(active_count)
	counts.fill(0)
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower is TowerBase:
			var angle_deg := rad_to_deg((tower.global_position - hex_grid.global_position).angle())
			var dir := _closest_active_direction(angle_deg, active_count)
			counts[dir] += 1

	var best := 0
	var best_count := counts[0]
	for i in active_count:
		if counts[i] < best_count:
			best_count = counts[i]
			best = i
	return best


func _closest_active_direction(angle_deg: float, active_count: int) -> int:
	var best := 0
	var best_diff := 360.0
	for i in active_count:
		var diff := absf(_angle_diff(angle_deg, DIRECTION_ANGLES_DEG[i]))
		if diff < best_diff:
			best_diff = diff
			best = i
	return best


func _angle_diff(a: float, b: float) -> float:
	return fmod(a - b + 540.0, 360.0) - 180.0


func _warning_position(dir: int) -> Vector2:
	var angle := deg_to_rad(DIRECTION_ANGLES_DEG[dir])
	var radius := (float(hex_grid.unlocked_radius) - 0.5) * hex_grid.hex_size
	if camera != null:
		radius = camera.current_visible_radius() * 0.85
	return hex_grid.global_position + Vector2(cos(angle), sin(angle)) * radius


func _on_enemy_died(_pos: Vector2 = Vector2.ZERO) -> void:
	kills += 1
	emit_signal("enemy_killed", kills)
