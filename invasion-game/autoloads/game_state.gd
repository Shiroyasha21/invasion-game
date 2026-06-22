extends Node

const STARTING_COINS := 1000
const ESSENCE_BASE_THRESHOLD := 8
const ESSENCE_GROWTH := 1.3
const RUN_DURATION := 1080.0  # 18 minutes

signal coins_changed(amount: int)
signal run_time_changed(seconds: float)
signal essence_changed(amount: int, to_next: int)
signal level_up(new_level: int)

var coins: int = STARTING_COINS
var run_time: float = 0.0
var towers_placed: int = 0

var essence: int = 0
var level: int = 0
var essence_to_next: int = ESSENCE_BASE_THRESHOLD


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


func add_essence(amount: int) -> void:
	essence += amount
	while essence >= essence_to_next:
		essence -= essence_to_next
		level += 1
		essence_to_next = int(ceil(essence_to_next * ESSENCE_GROWTH))
		emit_signal("level_up", level)
	emit_signal("essence_changed", essence, essence_to_next)


func reset() -> void:
	coins = STARTING_COINS
	towers_placed = 0
	run_time = 0.0
	essence = 0
	level = 0
	essence_to_next = ESSENCE_BASE_THRESHOLD
	emit_signal("coins_changed", coins)
	emit_signal("run_time_changed", run_time)
	emit_signal("essence_changed", essence, essence_to_next)
