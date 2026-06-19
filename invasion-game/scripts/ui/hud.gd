extends CanvasLayer

const TOWER_DATA_PATHS := [
	"res://resources/towers/tower_arrow.tres",
	"res://resources/towers/tower_cannon.tres",
	"res://resources/towers/tower_sniper.tres",
]

@onready var coin_label: Label = $MarginContainer/VBox/CoinLabel
@onready var time_label: Label = $MarginContainer/VBox/TimeLabel
@onready var hp_label: Label = $MarginContainer/VBox/HPLabel
@onready var shovel_button: Button = $ShovelButton
@onready var tower_bar: HBoxContainer = $TowerBar

var center_piece: CenterPiece
var _game: Node
var _tower_buttons: Array[Button] = []
var _tower_data: Array[TowerData] = []


func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.run_time_changed.connect(_on_run_time_changed)
	_on_coins_changed(GameState.coins)
	_on_run_time_changed(GameState.run_time)
	shovel_button.pressed.connect(_on_shovel_pressed)
	_setup_tower_bar()


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


func _on_coins_changed(amount: int) -> void:
	coin_label.text = "Coins: %d" % amount


func _on_run_time_changed(seconds: float) -> void:
	var total := int(seconds)
	time_label.text = "Time: %02d:%02d" % [total / 60, total % 60]


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]


func _setup_tower_bar() -> void:
	for path in TOWER_DATA_PATHS:
		_tower_data.append(load(path))

	for i in tower_bar.get_child_count():
		var button := tower_bar.get_child(i) as Button
		if button == null or i >= _tower_data.size():
			continue
		var data: TowerData = _tower_data[i]
		button.text = "%s\n%d" % [data.display_name, data.cost]
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
