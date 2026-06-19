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
	_mini_boss_timer = MINI_BOSS_INTERVAL
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
	var dir := randi() % _active_direction_count()
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
	emit_signal("mini_boss_spawned", boss)

	if wave_preview != null:
		wave_preview.flash_mini_boss_warning(_warning_position(dir))


func _spawn_position(dir: int, jitter_deg: float) -> Vector2:
	var jitter := randf_range(-jitter_deg, jitter_deg) if jitter_deg > 0.0 else 0.0
	var angle := deg_to_rad(DIRECTION_ANGLES_DEG[dir] + jitter)
	var tile_radius := (float(hex_grid.max_grid_radius) + SPAWN_MARGIN_TILES) * hex_grid.hex_size
	var spawn_radius := tile_radius
	if camera != null:
		spawn_radius = maxf(tile_radius, camera.max_visible_radius() * 1.15)
	return hex_grid.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius


func _warning_position(dir: int) -> Vector2:
	var angle := deg_to_rad(DIRECTION_ANGLES_DEG[dir])
	var radius := (float(hex_grid.unlocked_radius) - 0.5) * hex_grid.hex_size
	if camera != null:
		radius = camera.current_visible_radius() * 0.85
	return hex_grid.global_position + Vector2(cos(angle), sin(angle)) * radius


func _on_enemy_died(_pos: Vector2 = Vector2.ZERO) -> void:
	kills += 1
	emit_signal("enemy_killed", kills)
