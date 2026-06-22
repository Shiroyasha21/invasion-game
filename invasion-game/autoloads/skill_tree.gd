extends Node

# Centerpiece skill tree state. Shield is a player-activated emergency
# ability available from the start (on a cooldown); Vines and Weaken Boss
# are passive effects unlocked mid-run by spending coins. Towers/enemies/
# bosses read this singleton directly (see TowerBase.take_damage,
# EnemyBase.apply_slow, WaveManager._spawn_mini_boss) rather than needing
# per-instance wiring.

signal shield_changed(active: bool)
signal shield_cooldown_changed(remaining: float, ready: bool)
signal vines_triggered(radius: float, slow_mult: float, duration: float)
signal vines_unlocked_changed
signal weaken_unlocked_changed

const SHIELD_COOLDOWN := 30.0
const SHIELD_DURATION := 4.0
const VINES_COOLDOWN := 18.0
const VINES_DURATION := 3.0
const VINES_SLOW_MULT := 0.45
const VINES_RADIUS := 260.0
const WEAKEN_BOSS_MULT := 0.7
const VINES_COST := 800
const WEAKEN_COST := 1200

var vines_unlocked: bool = false
var weaken_unlocked: bool = false
var shield_active: bool = false
var shield_ready: bool = true
var running: bool = false

var _shield_active_timer: float = 0.0
var _shield_cooldown_timer: float = 0.0
var _vines_timer: float = VINES_COOLDOWN


func _ready() -> void:
	# Cooldowns must keep ticking even while the skill tree or level-up
	# screen pauses the game — otherwise checking the shield's status is
	# exactly what makes it look stuck.
	process_mode = Node.PROCESS_MODE_ALWAYS


func start() -> void:
	shield_active = false
	shield_ready = true
	_shield_active_timer = 0.0
	_shield_cooldown_timer = 0.0
	_vines_timer = VINES_COOLDOWN
	running = true


func stop() -> void:
	running = false


# Player-triggered: shields all towers from damage for SHIELD_DURATION,
# then goes on cooldown. Returns false if it's still on cooldown.
func try_activate_shield() -> bool:
	if not running or not shield_ready:
		return false
	shield_active = true
	shield_ready = false
	_shield_active_timer = SHIELD_DURATION
	_shield_cooldown_timer = SHIELD_COOLDOWN
	emit_signal("shield_changed", true)
	return true


func unlock_vines() -> bool:
	if vines_unlocked or not GameState.spend_coins(VINES_COST):
		return false
	vines_unlocked = true
	emit_signal("vines_unlocked_changed")
	return true


func unlock_weaken() -> bool:
	if weaken_unlocked or not GameState.spend_coins(WEAKEN_COST):
		return false
	weaken_unlocked = true
	emit_signal("weaken_unlocked_changed")
	return true


func boss_weaken_multiplier() -> float:
	return WEAKEN_BOSS_MULT if weaken_unlocked else 1.0


func reset() -> void:
	vines_unlocked = false
	weaken_unlocked = false
	shield_active = false
	shield_ready = true
	running = false


func _process(delta: float) -> void:
	if not running:
		return

	if shield_active:
		_shield_active_timer -= delta
		if _shield_active_timer <= 0.0:
			shield_active = false
			emit_signal("shield_changed", false)

	if not shield_ready:
		_shield_cooldown_timer -= delta
		if _shield_cooldown_timer <= 0.0:
			shield_ready = true
		emit_signal("shield_cooldown_changed", maxf(_shield_cooldown_timer, 0.0), shield_ready)

	if vines_unlocked:
		_vines_timer -= delta
		if _vines_timer <= 0.0:
			_vines_timer = VINES_COOLDOWN
			emit_signal("vines_triggered", VINES_RADIUS, VINES_SLOW_MULT, VINES_DURATION)
