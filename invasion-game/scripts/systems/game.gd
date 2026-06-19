extends Node2D

const GRID_UNLOCK_INTERVAL := 5  # waves between grid reveals

@onready var hex_grid: HexGridNode = $HexGrid
@onready var wave_manager: WaveManager = $WaveManager
@onready var coin_vacuum: CoinVacuum = $CoinVacuum
@onready var center_piece: CenterPiece = $CenterPiece
@onready var hud: CanvasLayer = $HUD
@onready var wave_preview: WavePreview = $WavePreview
@onready var camera: CameraZoom = $Camera2D

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene
@export var projectile_scene: PackedScene
@export var coin_scene: PackedScene

var _shovel_mode: bool = false


func _ready() -> void:
	wave_manager.enemy_scene = enemy_scene
	wave_manager.coin_scene = coin_scene
	wave_manager.center_piece = center_piece
	wave_manager.wave_preview = wave_preview
	wave_manager.init(hex_grid)
	wave_manager.wave_completed.connect(_on_wave_completed)
	center_piece.destroyed.connect(_on_game_over)
	center_piece.level_up.connect(_on_centerpiece_level_up)
	hud.init(center_piece, self)
	wave_preview.init(hex_grid)

	hex_grid.unlocked_radius_changed.connect(_on_unlocked_radius_changed)
	camera.set_unlock_progress(hex_grid.unlocked_radius, hex_grid.max_grid_radius)

	await get_tree().create_timer(2.0).timeout
	wave_manager.start_wave(1)


func toggle_shovel() -> void:
	_shovel_mode = !_shovel_mode
	hud.set_shovel_active(_shovel_mode)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)


func _handle_tap(screen_pos: Vector2) -> void:
	var world_pos := get_canvas_transform().affine_inverse() * screen_pos
	var hex := hex_grid.hex_at_pixel(world_pos)

	if _shovel_mode:
		_try_sell_tower(hex)
	else:
		_try_place_tower(hex)


func _try_place_tower(hex: Vector2i) -> void:
	if not hex_grid.is_valid_tile(hex):
		return
	if hex_grid.is_occupied(hex):
		return
	if hex == Vector2i.ZERO:
		return

	var tower: TowerBase = tower_scene.instantiate()
	tower.projectile_scene = projectile_scene
	tower.occupied_hex = hex
	add_child(tower)
	tower.add_to_group("towers")
	tower.global_position = hex_grid.hex_grid_to_pixel(hex)
	tower.destroyed.connect(_on_tower_destroyed)
	hex_grid.set_occupied(hex, true)


func _try_sell_tower(hex: Vector2i) -> void:
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower is TowerBase and tower.occupied_hex == hex:
			var refund := int(tower.cost * 0.5)
			GameState.add_coins(refund)
			hex_grid.set_occupied(hex, false)
			tower.queue_free()
			return


func _on_tower_destroyed(hex: Vector2i) -> void:
	hex_grid.set_occupied(hex, false)


func _on_wave_completed(wave_number: int) -> void:
	center_piece.on_wave_completed()
	if wave_number % GRID_UNLOCK_INTERVAL == 0:
		hex_grid.unlock_more()
	await get_tree().create_timer(3.0).timeout
	wave_manager.start_wave(wave_number + 1)


func _on_unlocked_radius_changed(new_radius: int) -> void:
	camera.set_unlock_progress(new_radius, hex_grid.max_grid_radius)
	print("Grid unlocked — radius now %d" % new_radius)


func _on_centerpiece_level_up(new_level: int) -> void:
	print("Tree grew to level %d" % new_level)


func _on_game_over() -> void:
	get_tree().paused = true
	print("GAME OVER — coins collected: %d" % GameState.coins)
