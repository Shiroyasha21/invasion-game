extends Node

const STARTING_COINS := 150

signal coins_changed(amount: int)
signal run_time_changed(seconds: float)

var coins: int = STARTING_COINS
var run_time: float = 0.0
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


func set_run_time(seconds: float) -> void:
	run_time = seconds
	emit_signal("run_time_changed", seconds)


func reset() -> void:
	coins = STARTING_COINS
	towers_placed = 0
	run_time = 0.0
	emit_signal("coins_changed", coins)
	emit_signal("run_time_changed", run_time)
