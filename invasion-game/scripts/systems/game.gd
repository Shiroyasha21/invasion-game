extends Node2D

@onready var hex_grid: HexGridNode = $HexGrid
@onready var wave_manager: WaveManager = $WaveManager

@export var enemy_scene: PackedScene


func _ready() -> void:
	wave_manager.enemy_scene = enemy_scene
	wave_manager.init(hex_grid)
	wave_manager.wave_completed.connect(_on_wave_completed)

	# Start first wave after a short delay
	await get_tree().create_timer(2.0).timeout
	wave_manager.start_wave(1)


func _on_wave_completed(wave_number: int) -> void:
	await get_tree().create_timer(3.0).timeout
	wave_manager.start_wave(wave_number + 1)
