extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Direction angles in radians: N, NE, SE, S, SW, NW (60 degrees apart)
const DIRECTION_ANGLES_DEG := [-90.0, -30.0, 30.0, 90.0, 150.0, -150.0]
const ARC_JITTER_DEG := 25.0

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0

var hex_grid: HexGridNode
var coin_scene: PackedScene
var center_piece: CenterPiece
var wave_preview: WavePreview
var current_wave: int = 0
var enemies_remaining: int = 0
var _spawn_timer: float = 0.0
var _spawn_queue: Array[Array] = []  # each entry: Array[int] of directions firing together


func init(grid: HexGridNode) -> void:
	hex_grid = grid


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	GameState.set_wave(wave_number)

	var dirs := _active_directions(wave_number)

	if wave_preview != null:
		var preview_points: Array[Vector2] = []
		for dir in dirs:
			preview_points.append(_spawn_position(dir, 0.0))
		wave_preview.show_preview(preview_points)
		await get_tree().create_timer(3.0).timeout
		wave_preview.hide_preview()

	_spawn_queue = _build_spawn_queue(wave_number)
	enemies_remaining = 0
	for group in _spawn_queue:
		enemies_remaining += group.size()
	_spawn_timer = 0.0
	emit_signal("wave_started", wave_number)


func _process(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()
		_spawn_timer = spawn_interval


func _build_spawn_queue(wave: int) -> Array[Array]:
	var queue: Array[Array] = []
	var active_dirs: Array[int] = _active_directions(wave)
	var sync_size := _sync_group_size(wave, active_dirs.size())
	var pulses := 3 + wave
	var dir_cursor := 0

	for _i in pulses:
		var group: Array[int] = []
		for _j in sync_size:
			group.append(active_dirs[dir_cursor % active_dirs.size()])
			dir_cursor += 1
		queue.append(group)
	return queue


func _active_directions(wave: int) -> Array[int]:
	# Directions: 0=N, 1=NE, 2=SE, 3=S, 4=SW, 5=NW
	if wave <= 2:
		return [0]
	elif wave <= 4:
		return [0, 3]
	elif wave <= 6:
		return [0, 2, 3, 5]
	else:
		return [0, 1, 2, 3, 4, 5]


func _sync_group_size(wave: int, dir_count: int) -> int:
	# Early waves stagger one direction at a time; later waves fire multiple
	# directions in the same pulse so the player feels genuinely surrounded.
	if wave <= 4:
		return 1
	elif wave <= 6:
		return mini(2, dir_count)
	else:
		return dir_count


func _enemy_difficulty_multiplier() -> float:
	return 1.0 + float(current_wave - 1) * 0.1


func _spawn_next() -> void:
	if _spawn_queue.is_empty() or enemy_scene == null:
		return

	var group: Array = _spawn_queue.pop_front()
	for dir in group:
		_spawn_enemy(dir)


func _spawn_enemy(dir: int) -> void:
	var spawn_pos := _spawn_position(dir, ARC_JITTER_DEG)
	var target_pos := center_piece.global_position if center_piece != null else hex_grid.global_position

	var enemy: EnemyBase = enemy_scene.instantiate()
	var difficulty := _enemy_difficulty_multiplier()
	enemy.coin_scene = coin_scene
	enemy.max_health *= difficulty
	enemy.attack_damage *= difficulty
	get_parent().add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_center.connect(_on_enemy_died.bind(Vector2.ZERO))
	enemy.init(spawn_pos, target_pos, center_piece)


func _spawn_position(dir: int, jitter_deg: float) -> Vector2:
	var jitter := randf_range(-jitter_deg, jitter_deg) if jitter_deg > 0.0 else 0.0
	var angle := deg_to_rad(DIRECTION_ANGLES_DEG[dir] + jitter)
	var radius := float(hex_grid.unlocked_radius + 1) * hex_grid.hex_size
	return hex_grid.global_position + Vector2(cos(angle), sin(angle)) * radius


func _on_enemy_died(_pos: Vector2) -> void:
	enemies_remaining -= 1
	if enemies_remaining <= 0 and _spawn_queue.is_empty():
		emit_signal("wave_completed", current_wave)
