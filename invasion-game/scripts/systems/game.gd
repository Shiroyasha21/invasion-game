extends Node2D

@onready var hex_grid: HexGridNode = $HexGrid
@onready var wave_manager: WaveManager = $WaveManager
@onready var coin_vacuum: CoinVacuum = $CoinVacuum
@onready var center_piece: CenterPiece = $CenterPiece
@onready var hud: CanvasLayer = $HUD
@onready var wave_preview: CanvasLayer = $WavePreview

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene
@export var projectile_scene: PackedScene
@export var coin_scene: PackedScene


func _ready() -> void:
	wave_manager.enemy_scene = enemy_scene
	wave_manager.coin_scene = coin_scene
	wave_manager.center_piece = center_piece
	wave_manager.wave_preview = wave_preview
	wave_manager.init(hex_grid)
	wave_manager.wave_completed.connect(_on_wave_completed)
	center_piece.destroyed.connect(_on_game_over)
	hud.init(center_piece)
	wave_preview.init(hex_grid)

	await get_tree().create_timer(2.0).timeout
	wave_manager.start_wave(1)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_try_place_tower(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_tower(event.position)


func _try_place_tower(screen_pos: Vector2) -> void:
	var world_pos := get_canvas_transform().affine_inverse() * screen_pos
	var hex := hex_grid.hex_at_pixel(world_pos)

	if not hex_grid.is_valid_tile(hex):
		return
	if hex_grid.is_occupied(hex):
		return
	if hex == Vector2i.ZERO:
		return

	var tower: TowerBase = tower_scene.instantiate()
	tower.projectile_scene = projectile_scene
	add_child(tower)
	tower.global_position = hex_grid.hex_grid_to_pixel(hex)
	hex_grid.set_occupied(hex, true)


func _on_wave_completed(wave_number: int) -> void:
	await get_tree().create_timer(3.0).timeout
	wave_manager.start_wave(wave_number + 1)


func _on_game_over() -> void:
	get_tree().paused = true
	print("GAME OVER — coins collected: %d" % GameState.coins)
