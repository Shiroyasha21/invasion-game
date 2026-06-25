extends CanvasLayer

const TOWER_DATA_PATHS := [
	"res://resources/towers/tower_arrow.tres",
	"res://resources/towers/tower_cannon.tres",
	"res://resources/towers/tower_sniper.tres",
	"res://resources/towers/tower_owl.tres",
	"res://resources/towers/tower_grenadier.tres",
]

@onready var coin_label: Label = $StatsPanel/CoinLabel
@onready var time_label: Label = $TimeLabel
@onready var hp_label: Label = $StatsPanel/HPLabel
@onready var level_label: Label = $StatsPanel/LevelLabel
@onready var attach_prompt_label: Label = $AttachPromptLabel
@onready var wave_banner_label: Label = $WaveBannerLabel
@onready var shovel_button: Button = $ActionRow/ShovelButton
@onready var skill_tree_button: Button = $ActionRow/SkillTreeButton
@onready var shield_button: Button = $ActionRow/ShieldButton
@onready var shield_label: Label = $ActionRow/ShieldButton/Row/Label
@onready var tower_bar: HBoxContainer = $TowerScroll/TowerBar
@onready var debug_log_label: Label = $DebugLogLabel

var center_piece: CenterPiece
var _game: Node
var _tower_buttons: Array[Button] = []
var _tower_data: Array[TowerData] = []
var _wave_banner_timer: SceneTreeTimer = null


func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.run_time_changed.connect(_on_run_time_changed)
	GameState.essence_changed.connect(_on_essence_changed)
	_on_coins_changed(GameState.coins)
	_on_run_time_changed(GameState.run_time)
	_on_essence_changed(GameState.essence, GameState.essence_to_next)
	shovel_button.pressed.connect(_on_shovel_pressed)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	shield_button.pressed.connect(_on_shield_pressed)
	SkillTree.shield_changed.connect(_on_shield_changed)
	SkillTree.shield_cooldown_changed.connect(_on_shield_cooldown_changed)
	_update_shield_button()
	_setup_tower_bar()

	debug_log_label.text = DebugLog.get_text()
	DebugLog.logged.connect(func(_line): debug_log_label.text = DebugLog.get_text())


func init(cp: CenterPiece, game: Node) -> void:
	center_piece = cp
	_game = game
	center_piece.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(cp.current_hp, cp.max_hp)
	if _tower_buttons.size() > 0:
		_select_tower(_tower_buttons[0], _tower_data[0])


func set_shovel_active(active: bool) -> void:
	if active:
		shovel_button.modulate = Color(1.0, 0.85, 0.1)
	else:
		shovel_button.modulate = Color(1.0, 1.0, 1.0)


func _on_shovel_pressed() -> void:
	_game.toggle_shovel()


func _on_skill_tree_pressed() -> void:
	_game.open_skill_tree()


func _on_shield_pressed() -> void:
	_game.activate_shield()


func _on_shield_changed(_active: bool) -> void:
	_update_shield_button()


func _on_shield_cooldown_changed(remaining: float, _ready: bool) -> void:
	_update_shield_button(remaining)


func _update_shield_button(cooldown_remaining: float = 0.0) -> void:
	if SkillTree.shield_active:
		shield_label.text = "Active"
		shield_button.disabled = true
	elif not SkillTree.shield_ready:
		shield_label.text = "%ds" % ceili(cooldown_remaining)
		shield_button.disabled = true
	else:
		shield_label.text = "Shield"
		shield_button.disabled = false


func show_wave_banner(text: String) -> void:
	wave_banner_label.text = text
	wave_banner_label.visible = true
	_wave_banner_timer = get_tree().create_timer(2.2)
	_wave_banner_timer.timeout.connect(func(): wave_banner_label.visible = false)


func _on_coins_changed(amount: int) -> void:
	coin_label.text = "Coins: %d" % amount


func _on_run_time_changed(seconds: float) -> void:
	var remaining := maxi(int(GameState.RUN_DURATION - seconds), 0)
	time_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]


func _on_essence_changed(amount: int, to_next: int) -> void:
	level_label.text = "Lv %d  (%d/%d)" % [GameState.level, amount, to_next]


func set_attach_prompt(title: String) -> void:
	attach_prompt_label.text = "Tap a tower to attach: %s" % title
	attach_prompt_label.visible = true


func clear_attach_prompt() -> void:
	attach_prompt_label.visible = false


func _setup_tower_bar() -> void:
	for path in TOWER_DATA_PATHS:
		_tower_data.append(load(path))

	for i in tower_bar.get_child_count():
		var button := tower_bar.get_child(i) as Button
		if button == null or i >= _tower_data.size():
			continue
		var data: TowerData = _tower_data[i]

		var icon := button.get_node("VBox/Icon") as TowerIcon
		if icon != null:
			icon.animal_type = data.animal_type
			icon.body_color = data.body_color
			icon.queue_redraw()

		var name_label := button.get_node("VBox/NameLabel") as Label
		if name_label != null:
			name_label.text = data.display_name
		var cost_label := button.get_node("VBox/CostLabel") as Label
		if cost_label != null:
			cost_label.text = str(data.cost)

		button.pressed.connect(_on_tower_button_pressed.bind(button, data))
		_tower_buttons.append(button)


func _on_tower_button_pressed(button: Button, data: TowerData) -> void:
	_select_tower(button, data)


func _select_tower(button: Button, data: TowerData) -> void:
	for b in _tower_buttons:
		b.modulate = Color(1.0, 1.0, 1.0)
	button.modulate = Color(0.6, 1.0, 0.6)
	if _game != null:
		_game.select_tower_type(data)
