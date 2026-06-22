extends Node
class_name WaveManager

signal run_time_updated(elapsed: float)
signal mini_boss_spawned(boss: MiniBoss)
signal enemy_killed(total_kills: int)
signal wave_cleared(wave_index: int)
signal wave_incoming(wave_index: int)

# Direction angles in degrees: N, NE, SE, S, SW, NW (60 degrees apart)
const DIRECTION_ANGLES_DEG := [-90.0, -30.0, 30.0, 90.0, 150.0, -150.0]
const ARC_JITTER_DEG := 25.0
const SPAWN_MARGIN_TILES := 3.0  # extra tiles beyond the rendered grid so enemies appear off-screen

# Each wave ramps from a calm trickle up to a full-surround climax. Most wave
# transitions roll straight into the next wave (just resetting the ramp back
# to calm — a brief "slow down" without a hard stop). A real breather (no
# spawns at all) only happens when a new enemy type is about to be introduced,
# or periodically every few waves otherwise. Breathers shrink as the run
# clock nears the end, so the back half of the run stays relentless.
const WAVE_ACTIVE_DURATION := 55.0
const UNLOCK_WAVES := [1, 3, 5, 8]  # must match _apply_enemy_profile's thresholds
const PERIODIC_REST_INTERVAL := 3
const UNLOCK_REST_BASE := 14.0
const UNLOCK_REST_MIN := 4.0
const PERIODIC_REST_BASE := 7.0
const PERIODIC_REST_MIN := 1.5

const BASE_SPAWN_INTERVAL := 2.2
const MIN_SPAWN_INTERVAL := 0.45

const DIFFICULTY_GROWTH_PER_MIN := 0.10
const MINI_BOSS_INTERVAL := 90.0
const FIRST_MINI_BOSS_DELAY := 270.0  # 4:30 — give the player more time to build up before the first boss
const MINI_BOSS_TELEGRAPH_SECONDS := 3.0  # warning shows this long before the boss actually appears
const WEALTHY_CHANCE := 0.12  # fraction of regular enemies that drop a big bonus
const WEALTHY_COIN_MULT := 6
const WEALTHY_ESSENCE_MULT := 2

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
var current_wave_index: int = 0

var _spawn_timer: float = 0.0
var _mini_boss_timer: float = MINI_BOSS_INTERVAL
var _resting: bool = false
var _phase_time_left: float = WAVE_ACTIVE_DURATION


func init(grid: HexGridNode) -> void:
	hex_grid = grid


func start_run() -> void:
	elapsed_time = 0.0
	kills = 0
	current_wave_index = 0
	_resting = false
	_phase_time_left = WAVE_ACTIVE_DURATION
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

	_phase_time_left -= delta
	if _resting:
		if _phase_time_left <= 0.0:
			_begin_wave(current_wave_index + 1)
		return

	if _phase_time_left <= 0.0:
		_advance_wave()

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


func _run_progress() -> float:
	return clampf(elapsed_time / GameState.RUN_DURATION, 0.0, 1.0)


func _wave_progress() -> float:
	return clampf(1.0 - _phase_time_left / WAVE_ACTIVE_DURATION, 0.0, 1.0)


func _advance_wave() -> void:
	var next_wave := current_wave_index + 1
	if _should_rest_before(next_wave):
		_resting = true
		_phase_time_left = _rest_duration_for(next_wave)
		emit_signal("wave_cleared", current_wave_index)
	else:
		_begin_wave(next_wave)


func _begin_wave(wave_index: int) -> void:
	current_wave_index = wave_index
	_resting = false
	_phase_time_left = WAVE_ACTIVE_DURATION
	emit_signal("wave_incoming", wave_index)


func _should_rest_before(wave_index: int) -> bool:
	return wave_index in UNLOCK_WAVES or wave_index % PERIODIC_REST_INTERVAL == 0


func _rest_duration_for(wave_index: int) -> float:
	var t := _run_progress()
	if wave_index in UNLOCK_WAVES:
		return lerpf(UNLOCK_REST_BASE, UNLOCK_REST_MIN, t)
	return lerpf(PERIODIC_REST_BASE, PERIODIC_REST_MIN, t)


func _current_spawn_interval() -> float:
	return lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, _wave_progress())


func _difficulty_multiplier() -> float:
	return 1.0 + _elapsed_minutes() * DIFFICULTY_GROWTH_PER_MIN


func _coin_value_for_time() -> int:
	return mini(2 + int(_elapsed_minutes() / 1.8), 14)


func _max_directions_for_wave(wave_index: int) -> int:
	return clampi(1 + wave_index, 1, 6)


func _max_sync_for_wave(wave_index: int) -> int:
	return clampi(1 + int(wave_index / 2.0), 1, 6)


func _active_direction_count() -> int:
	var max_dirs := _max_directions_for_wave(current_wave_index)
	return clampi(roundi(lerpf(1.0, float(max_dirs), _wave_progress())), 1, max_dirs)


func _sync_size() -> int:
	var max_sync := mini(_max_sync_for_wave(current_wave_index), _active_direction_count())
	return clampi(roundi(lerpf(1.0, float(max_sync), _wave_progress())), 1, max_sync)


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

	if randf() < WEALTHY_CHANCE:
		enemy.is_wealthy = true
		enemy.coin_value *= WEALTHY_COIN_MULT
		enemy.essence_value *= WEALTHY_ESSENCE_MULT

	_apply_enemy_profile(enemy)

	get_parent().add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_center.connect(_on_enemy_died)
	enemy.init(spawn_pos, target_pos, center_piece)

	# Warning markers help the player learn the surround mechanic early on,
	# but once hordes are spawning every fraction of a second they're just
	# screen clutter — drop them after the first few waves.
	if wave_preview != null and current_wave_index <= 2:
		wave_preview.flash_warning(_warning_position(dir))


# Behavior variants unlock one wave at a time (must match UNLOCK_WAVES above)
# — each new type's first appearances land in that wave's slow opening ramp,
# right after the breather that introduces it.
func _apply_enemy_profile(enemy: EnemyBase) -> void:
	var wave := current_wave_index
	var choices: Array[String] = ["normal"]
	if wave >= 1:
		choices.append("fast")
	if wave >= 3:
		choices.append("tanky")
	if wave >= 5:
		choices.append("flanker")
	if wave >= 8:
		choices.append("flying")

	match choices[randi() % choices.size()]:
		"fast":
			enemy.is_fast = true
		"tanky":
			enemy.is_tanky = true
			enemy.max_health *= 2.5
			enemy.move_speed *= 0.7
		"flanker":
			enemy.is_flanker = true
		"flying":
			enemy.is_flying = true


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
	boss.tower_displaced.connect(_on_tower_displaced)
	boss.init(spawn_pos, target_pos, center_piece)
	boss.setup_from_data(data, minutes)

	var weaken := SkillTree.boss_weaken_multiplier()
	boss.attack_damage *= weaken
	boss.max_health *= weaken
	boss.current_health = boss.max_health

	boss.coin_value = data.coin_reward
	boss.essence_value = data.essence_reward
	emit_signal("mini_boss_spawned", boss)


# Knocks a tower to a random open tile instead of damaging it.
func _on_tower_displaced(tower: TowerBase) -> void:
	var candidates: Array[Vector2i] = []
	for hex in hex_grid.tiles.keys():
		if hex == Vector2i.ZERO:
			continue
		if hex_grid.is_valid_tile(hex) and not hex_grid.is_occupied(hex):
			candidates.append(hex)
	if candidates.is_empty():
		return

	var new_hex: Vector2i = candidates[randi() % candidates.size()]
	hex_grid.set_occupied(tower.occupied_hex, false)
	hex_grid.set_occupied(new_hex, true)
	tower.occupied_hex = new_hex
	tower.global_position = hex_grid.hex_grid_to_pixel(new_hex)


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
