extends Control

const GAME_SCENE_PATH := "res://scenes/game/Game.tscn"
const EXIT_CONFIRM_WINDOW := 2.0

@onready var start_button: Button = $ButtonPanel/VBox/StartButton
@onready var settings_button: Button = $ButtonPanel/VBox/SettingsButton
@onready var quit_button: Button = $ButtonPanel/VBox/QuitButton

@onready var settings_panel: Panel = $SettingsPanel
@onready var portrait_button: Button = $SettingsPanel/Box/OrientationRow/PortraitButton
@onready var landscape_button: Button = $SettingsPanel/Box/OrientationRow/LandscapeButton
@onready var volume_slider: HSlider = $SettingsPanel/Box/VolumeSlider
@onready var close_button: Button = $SettingsPanel/Box/CloseButton

@onready var exit_toast: Label = $ExitToast

var _awaiting_exit_confirm: bool = false


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	portrait_button.pressed.connect(_on_portrait_pressed)
	landscape_button.pressed.connect(_on_landscape_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(_on_close_settings_pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


func _on_back_pressed() -> void:
	if settings_panel.visible:
		settings_panel.visible = false
		return
	if _awaiting_exit_confirm:
		get_tree().quit()
		return
	_awaiting_exit_confirm = true
	exit_toast.visible = true
	get_tree().create_timer(EXIT_CONFIRM_WINDOW).timeout.connect(func():
		_awaiting_exit_confirm = false
		exit_toast.visible = false
	)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	portrait_button.button_pressed = Settings.orientation == "portrait"
	landscape_button.button_pressed = Settings.orientation == "landscape"
	volume_slider.value = Settings.master_volume
	settings_panel.visible = true


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false


func _on_portrait_pressed() -> void:
	portrait_button.button_pressed = true
	landscape_button.button_pressed = false
	Settings.set_orientation("portrait")


func _on_landscape_pressed() -> void:
	landscape_button.button_pressed = true
	portrait_button.button_pressed = false
	Settings.set_orientation("landscape")


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
