extends CanvasLayer
class_name ObjectivesScreen

signal start_pressed

@onready var start_button: Button = $Panel/VBox/StartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_on_start_pressed)


func open() -> void:
	visible = true
	get_tree().paused = true


func _on_start_pressed() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("start_pressed")
