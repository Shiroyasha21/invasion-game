extends Control

const GAME_SCENE_PATH := "res://scenes/game/Game.tscn"

@onready var start_button: Button = $VBox/StartButton
@onready var quit_button: Button = $VBox/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
