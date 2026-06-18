extends Node

signal coins_changed(amount: int)
signal wave_changed(wave: int)

var coins: int = 0
var current_wave: int = 0
var towers_placed: int = 0


func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	emit_signal("coins_changed", coins)
	return true


func set_wave(wave: int) -> void:
	current_wave = wave
	emit_signal("wave_changed", wave)


func reset() -> void:
	coins = 0
	towers_placed = 0
	current_wave = 0
	emit_signal("coins_changed", coins)
	emit_signal("wave_changed", current_wave)
