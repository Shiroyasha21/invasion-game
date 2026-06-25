extends Node

const SETTINGS_PATH := "user://settings.cfg"

signal orientation_changed(new_orientation: String)
signal master_volume_changed(new_volume: float)

var orientation: String = "portrait"  # "portrait" or "landscape"
var master_volume: float = 1.0  # 0..1


func _ready() -> void:
	_load()
	_apply_orientation()
	_apply_master_volume()


func set_orientation(value: String) -> void:
	if orientation == value:
		return
	orientation = value
	_apply_orientation()
	_save()
	emit_signal("orientation_changed", orientation)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	_save()
	emit_signal("master_volume_changed", master_volume)


func _apply_orientation() -> void:
	if orientation == "landscape":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	else:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)


func _apply_master_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume))


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		orientation = cfg.get_value("display", "orientation", "portrait")
		master_volume = cfg.get_value("audio", "master_volume", 1.0)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "orientation", orientation)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(SETTINGS_PATH)
