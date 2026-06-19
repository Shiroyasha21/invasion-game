extends Node

# Tracks global, run-scoped tower upgrades picked from level-up cards.
# Multipliers are keyed by tower id ("arrow", "cannon", "sniper"); the
# special ALL_KEY applies to every tower type at once. Towers read these
# live (see TowerBase._effective_*), so upgrades affect existing AND future
# towers of the targeted type immediately.

const ALL_KEY := "_all"

var _damage_mult: Dictionary = {}
var _range_mult: Dictionary = {}
var _fire_rate_mult: Dictionary = {}
var _splash_mult: Dictionary = {}


func add_damage_mult(tower_id: String, amount: float) -> void:
	var key := tower_id if tower_id != "" else ALL_KEY
	_damage_mult[key] = _damage_mult.get(key, 1.0) + amount


func add_range_mult(tower_id: String, amount: float) -> void:
	var key := tower_id if tower_id != "" else ALL_KEY
	_range_mult[key] = _range_mult.get(key, 1.0) + amount


func add_fire_rate_mult(tower_id: String, amount: float) -> void:
	var key := tower_id if tower_id != "" else ALL_KEY
	_fire_rate_mult[key] = _fire_rate_mult.get(key, 1.0) + amount


func add_splash_mult(tower_id: String, amount: float) -> void:
	var key := tower_id if tower_id != "" else ALL_KEY
	_splash_mult[key] = _splash_mult.get(key, 1.0) + amount


func damage_multiplier(tower_id: String) -> float:
	return _damage_mult.get(tower_id, 1.0) * _damage_mult.get(ALL_KEY, 1.0)


func range_multiplier(tower_id: String) -> float:
	return _range_mult.get(tower_id, 1.0) * _range_mult.get(ALL_KEY, 1.0)


func fire_rate_multiplier(tower_id: String) -> float:
	return _fire_rate_mult.get(tower_id, 1.0) * _fire_rate_mult.get(ALL_KEY, 1.0)


func splash_multiplier(tower_id: String) -> float:
	return _splash_mult.get(tower_id, 1.0) * _splash_mult.get(ALL_KEY, 1.0)


func reset() -> void:
	_damage_mult.clear()
	_range_mult.clear()
	_fire_rate_mult.clear()
	_splash_mult.clear()
