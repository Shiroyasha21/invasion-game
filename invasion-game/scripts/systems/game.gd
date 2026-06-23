extends Node2D

const GRID_UNLOCK_INTERVAL_SECONDS := 130.0  # full board unlocked by ~8:40
const CARDS_PER_LEVEL_UP := 3

@onready var hex_grid: HexGridNode = $HexGrid
@onready var wave_manager: WaveManager = $WaveManager
@onready var coin_vacuum: CoinVacuum = $CoinVacuum
@onready var center_piece: CenterPiece = $CenterPiece
@onready var hud: CanvasLayer = $HUD
@onready var wave_preview: WavePreview = $WavePreview
@onready var camera: CameraZoom = $Camera2D
@onready var level_up_ui: LevelUpUI = $LevelUpUI
@onready var skill_tree_ui: SkillTreeUI = $SkillTreeUI
@onready var objectives_screen: ObjectivesScreen = $ObjectivesScreen
@onready var end_screen: EndScreen = $EndScreen

@export var enemy_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var tower_scene: PackedScene
@export var projectile_scene: PackedScene
@export var coin_scene: PackedScene

var _shovel_mode: bool = false
var _attach_mode: bool = false
var _pending_rare_attachment: RareAttachmentData = null
var selected_tower_data: TowerData = null
var _next_grid_unlock_time: float = GRID_UNLOCK_INTERVAL_SECONDS
var _run_ended: bool = false


func _ready() -> void:
	wave_manager.enemy_scene = enemy_scene
	wave_manager.mini_boss_scene = mini_boss_scene
	wave_manager.coin_scene = coin_scene
	wave_manager.projectile_scene = projectile_scene
	wave_manager.center_piece = center_piece
	wave_manager.wave_preview = wave_preview
	wave_manager.camera = camera
	wave_manager.init(hex_grid)
	center_piece.destroyed.connect(_on_game_over)
	hud.init(center_piece, self)
	wave_preview.init(hex_grid)

	hex_grid.unlocked_radius_changed.connect(_on_unlocked_radius_changed)
	camera.set_unlock_progress(hex_grid.unlocked_radius, hex_grid.max_grid_radius)

	GameState.run_time_changed.connect(_on_run_time_changed)
	GameState.level_up.connect(_on_player_level_up)
	level_up_ui.card_chosen.connect(_on_card_chosen)
	SkillTree.vines_triggered.connect(_on_vines_triggered)
	SkillTree.vines_unlocked_changed.connect(_on_skill_unlocked)
	SkillTree.weaken_unlocked_changed.connect(_on_skill_unlocked)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.wave_incoming.connect(_on_wave_incoming)

	objectives_screen.start_pressed.connect(_on_objectives_start)
	objectives_screen.open()


func _on_objectives_start() -> void:
	wave_manager.start_run()
	SkillTree.start()


func toggle_shovel() -> void:
	_shovel_mode = !_shovel_mode
	hud.set_shovel_active(_shovel_mode)


func select_tower_type(data: TowerData) -> void:
	selected_tower_data = data


func open_skill_tree() -> void:
	skill_tree_ui.open()


func activate_shield() -> void:
	if SkillTree.try_activate_shield():
		SFX.play_shield_activate()


func _on_wave_cleared(_wave_index: int) -> void:
	SFX.play_wave_cleared()
	hud.show_wave_banner("All Clear")


func _on_wave_incoming(wave_index: int) -> void:
	if wave_index == 0:
		return
	SFX.play_wave_incoming()
	hud.show_wave_banner("Swarm Incoming")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)


func _handle_tap(screen_pos: Vector2) -> void:
	var world_pos := get_canvas_transform().affine_inverse() * screen_pos
	var hex := hex_grid.hex_at_pixel(world_pos)

	if _attach_mode:
		_try_attach_rare(hex)
	elif _shovel_mode:
		_try_sell_tower(hex)
	elif hex == Vector2i.ZERO:
		skill_tree_ui.open()
	else:
		_try_place_tower(hex)


func _on_vines_triggered(radius: float, slow_mult: float, duration: float) -> void:
	var center := center_piece.global_position
	wave_preview.flash_vine_wave(center, radius)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyBase and node.global_position.distance_to(center) <= radius:
			node.apply_slow(slow_mult, duration)


# Tree growth is tied to skill-tree unlocks and level milestones, not waves.
func _on_skill_unlocked() -> void:
	center_piece.grow()


func _try_place_tower(hex: Vector2i) -> void:
	if selected_tower_data == null:
		return
	if not hex_grid.is_valid_tile(hex):
		return
	if hex_grid.is_occupied(hex):
		return
	if not GameState.spend_coins(selected_tower_data.cost):
		return

	var tower: TowerBase = tower_scene.instantiate()
	tower.setup(selected_tower_data)
	tower.projectile_scene = projectile_scene
	tower.occupied_hex = hex
	add_child(tower)
	tower.add_to_group("towers")
	tower.global_position = hex_grid.hex_grid_to_pixel(hex)
	tower.destroyed.connect(_on_tower_destroyed)
	hex_grid.set_occupied(hex, true)
	SFX.play_place_tower()


func _try_sell_tower(hex: Vector2i) -> void:
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower is TowerBase and tower.occupied_hex == hex:
			var refund := int(tower.cost * 0.5)
			GameState.add_coins(refund)
			hex_grid.set_occupied(hex, false)
			tower.queue_free()
			SFX.play_sell_tower()
			return


func _try_attach_rare(hex: Vector2i) -> void:
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower is TowerBase and tower.occupied_hex == hex:
			tower.rare_attachment = _pending_rare_attachment
			tower.queue_redraw()
			_attach_mode = false
			_pending_rare_attachment = null
			hud.clear_attach_prompt()
			return


func _on_tower_destroyed(hex: Vector2i) -> void:
	hex_grid.set_occupied(hex, false)


func _on_run_time_changed(seconds: float) -> void:
	if _run_ended:
		return
	if seconds >= _next_grid_unlock_time:
		hex_grid.unlock_more()
		_next_grid_unlock_time += GRID_UNLOCK_INTERVAL_SECONDS
	if seconds >= GameState.RUN_DURATION:
		_on_run_survived()


func _on_unlocked_radius_changed(new_radius: int) -> void:
	camera.set_unlock_progress(new_radius, hex_grid.max_grid_radius)


func _on_player_level_up(new_level: int) -> void:
	SFX.play_level_up()
	if new_level % 4 == 0:
		center_piece.grow()
	var cards := UpgradePool.draw(CARDS_PER_LEVEL_UP)
	level_up_ui.show_cards(new_level, cards)


func _on_card_chosen(card: UpgradeCard) -> void:
	match card.kind:
		UpgradeCard.Kind.RARE:
			_pending_rare_attachment = card.rare_data
			_attach_mode = true
			hud.set_attach_prompt(card.rare_data.title)
		_:
			_apply_stat_card(card)


func _apply_stat_card(card: UpgradeCard) -> void:
	match card.stat:
		"damage":
			BuildState.add_damage_mult(card.tower_id, card.amount)
		"range":
			BuildState.add_range_mult(card.tower_id, card.amount)
		"fire_rate":
			BuildState.add_fire_rate_mult(card.tower_id, card.amount)
		"splash":
			BuildState.add_splash_mult(card.tower_id, card.amount)


func _on_run_survived() -> void:
	_run_ended = true
	wave_manager.stop_run()
	SkillTree.stop()
	end_screen.show_result(true, GameState.run_time, wave_manager.kills, GameState.coins, GameState.level)


func _on_game_over() -> void:
	_run_ended = true
	wave_manager.stop_run()
	SkillTree.stop()
	end_screen.show_result(false, GameState.run_time, wave_manager.kills, GameState.coins, GameState.level)
