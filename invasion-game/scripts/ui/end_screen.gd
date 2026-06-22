extends CanvasLayer
class_name EndScreen

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)


func show_result(won: bool, time_survived: float, kills: int, coins: int, level: int) -> void:
	title_label.text = "VICTORY!" if won else "GAME OVER"
	title_label.modulate = Color(0.6, 1.0, 0.5) if won else Color(1.0, 0.45, 0.4)
	var total := int(time_survived)
	stats_label.text = "Time survived: %02d:%02d\nEnemies defeated: %d\nCoins collected: %d\nLevel reached: %d" % [total / 60, total % 60, kills, coins, level]
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	GameState.reset()
	BuildState.reset()
	SkillTree.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
