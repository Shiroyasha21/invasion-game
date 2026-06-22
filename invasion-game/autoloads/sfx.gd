extends Node

# Procedurally-generated placeholder sound effects — no audio assets needed.
# Swap any play_*() body for AudioStreamPlayer + a real .wav later without
# touching call sites elsewhere in the codebase.

const SAMPLE_RATE := 22050
const POOL_SIZE := 8

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _cache: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play_shoot() -> void:
	_play(_tone(900.0, 0.06, "square", 0.22), _rand_pitch())


func play_splash() -> void:
	_play(_tone(220.0, 0.18, "square", 0.3), _rand_pitch())


func play_laser() -> void:
	_play(_tone(1400.0, 0.05, "sine", 0.18), _rand_pitch())


func play_hit() -> void:
	_play(_tone(180.0, 0.07, "noise", 0.2), _rand_pitch())


func play_coin() -> void:
	_play(_tone(1200.0, 0.08, "sine", 0.28), _rand_pitch())


func play_death() -> void:
	_play(_tone(140.0, 0.22, "noise", 0.28), _rand_pitch())


func play_tower_destroyed() -> void:
	_play(_tone(90.0, 0.4, "noise", 0.35))


func play_level_up() -> void:
	_play(_sweep(440.0, 880.0, 0.3, "sine", 0.4))


func play_place_tower() -> void:
	_play(_tone(500.0, 0.1, "sine", 0.28))


func play_sell_tower() -> void:
	_play(_tone(300.0, 0.12, "sine", 0.28))


func play_boss_warning() -> void:
	_play(_tone(200.0, 0.5, "square", 0.4))


func play_wave_cleared() -> void:
	_play(_sweep(420.0, 620.0, 0.35, "sine", 0.35))


func play_wave_incoming() -> void:
	_play(_sweep(420.0, 260.0, 0.3, "square", 0.3))


func play_shield_activate() -> void:
	_play(_sweep(500.0, 900.0, 0.2, "sine", 0.35))


# Owl: sharp descending screech.
func play_owl_screech() -> void:
	_play(_sweep(2200.0, 900.0, 0.12, "sine", 0.25), _rand_pitch())


# Grenadier: low thud as the grenade leaves the launcher.
func play_grenade_launch() -> void:
	_play(_sweep(220.0, 80.0, 0.15, "square", 0.3))


# Grenadier impact / splash detonation.
func play_explosion() -> void:
	_play(_tone(70.0, 0.35, "noise", 0.4))
	_play(_sweep(300.0, 60.0, 0.3, "square", 0.25))


# Chest pickup (Essence) — a brighter two-note chime, distinct from coins.
func play_chest_open() -> void:
	_play(_tone(520.0, 0.12, "sine", 0.3))
	_play(_tone(780.0, 0.16, "sine", 0.3))


func _rand_pitch() -> float:
	return randf_range(0.92, 1.08)


func _play(stream: AudioStreamWAV, pitch_scale: float = 1.0) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.play()


func _tone(freq: float, duration: float, wave: String, volume: float) -> AudioStreamWAV:
	return _sweep(freq, freq, duration, wave, volume)


# Generates a tone that slides from start_freq to end_freq over its
# duration — a flat tone is just a sweep with matching start/end frequency.
func _sweep(start_freq: float, end_freq: float, duration: float, wave: String, volume: float) -> AudioStreamWAV:
	var key := "%s_%.1f_%.1f_%.3f_%.2f" % [wave, start_freq, end_freq, duration, volume]
	if _cache.has(key):
		return _cache[key]

	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono
	var phase := 0.0
	for i in sample_count:
		var t := float(i) / sample_count
		var freq := lerpf(start_freq, end_freq, t)
		phase += freq / SAMPLE_RATE
		var envelope := 1.0 - t  # fade-out avoids clicks
		var sample: float
		match wave:
			"square":
				sample = 1.0 if sin(TAU * phase) >= 0.0 else -1.0
			"noise":
				sample = randf_range(-1.0, 1.0)
			_:
				sample = sin(TAU * phase)
		sample *= envelope * volume
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	_cache[key] = stream
	return stream
