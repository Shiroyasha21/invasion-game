extends CanvasLayer

@onready var coin_label: Label = $MarginContainer/VBox/CoinLabel
@onready var wave_label: Label = $MarginContainer/VBox/WaveLabel
@onready var hp_label: Label = $MarginContainer/VBox/HPLabel

var center_piece: CenterPiece


func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	_on_coins_changed(GameState.coins)
	_on_wave_changed(GameState.current_wave)


func init(cp: CenterPiece) -> void:
	center_piece = cp
	center_piece.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(cp.current_hp, cp.max_hp)


func _on_coins_changed(amount: int) -> void:
	coin_label.text = "Coins: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave: %d" % wave


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]
