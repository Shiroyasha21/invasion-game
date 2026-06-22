extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 50.0
@export var max_health: float = 30.0
@export var coin_scene: PackedScene
@export var coin_value: int = 1
@export var essence_value: int = 1
@export var is_wealthy: bool = false
@export var damage_to_center: float = 10.0

@export var attack_damage: float = 8.0
@export var attack_speed: float = 1.0

# Behavior variants — toggled per-instance by WaveManager, all sharing this
# one scene/script instead of needing separate enemy types.
@export var is_flying: bool = false  # ignores tower collision, flies straight over
@export var is_fast: bool = false  # accelerates the longer it's alive
@export var is_flanker: bool = false  # arcs partway around before committing to center
@export var is_tanky: bool = false  # visual cue only; stats set by WaveManager

const ACCEL_MAX_MULT := 1.8
const ACCEL_SECONDS := 4.0
const FLANK_ANGLE_DEG := 90.0
const DAMAGE_FLASH_DURATION := 0.15

var current_health: float
var target_position: Vector2 = Vector2.ZERO
var center_piece: CenterPiece
var _blocked_by: TowerBase = null
var _attack_timer: float = 0.0
var _base_move_speed: float = 0.0
var _age: float = 0.0
var _flank_point: Vector2 = Vector2.ZERO
var _reached_flank: bool = false
var _damage_flash: float = 0.0
var _slow_mult: float = 1.0
var _slow_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	_base_move_speed = move_speed
	if is_flying:
		collision_mask = 0
	add_to_group("enemies")


func _draw() -> void:
	var type_color := Color(0.9, 0.2, 0.2)
	var radius := 20.0
	if is_flying:
		type_color = Color(0.4, 0.8, 1.0)
		radius = 16.0
	elif is_fast:
		type_color = Color(1.0, 0.55, 0.1)
	elif is_flanker:
		type_color = Color(0.7, 0.3, 0.9)
	if is_tanky:
		radius = 27.0

	# Flying enemies cast a smaller, more offset shadow to read as hovering.
	var shadow_offset := Vector2(3.0, radius * 0.4) if not is_flying else Vector2(5.0, radius * 0.65)
	var shadow_scale := 0.55 if not is_flying else 0.4
	draw_set_transform(shadow_offset, 0.0, Vector2(1.0, shadow_scale))
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.0, 0.0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var fill := Color(1.0, 0.85, 0.1) if is_wealthy else type_color
	if _slow_timer > 0.0:
		fill = fill.lerp(Color(0.2, 0.7, 0.3), 0.6)
	fill = fill.lerp(Color.WHITE, _damage_flash / DAMAGE_FLASH_DURATION)

	if is_flying:
		for side in [-1.0, 1.0]:
			draw_set_transform(Vector2(-radius * 0.2, side * radius * 0.9), 0.0, Vector2(1.6, 0.7))
			draw_circle(Vector2.ZERO, radius * 0.55, Color(1.0, 1.0, 1.0, 0.4))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Body: oval abdomen (rear) + smaller round head (front) + legs, instead
	# of a single circle — reads as a bug rather than a dot.
	draw_set_transform(Vector2(-radius * 0.2, 0), 0.0, Vector2(1.25, 0.85))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(radius * 0.75, 0), radius * 0.55, fill.darkened(0.12))
	draw_arc(Vector2(-radius * 0.2, 0), radius * 1.25, 0, TAU, 18, type_color.lightened(0.3), 2.0)

	var leg_color := type_color.darkened(0.45)
	if not is_flying:
		for side in [-1.0, 1.0]:
			for i in 3:
				var lx := -radius * 0.5 + i * radius * 0.45
				draw_line(Vector2(lx, side * radius * 0.55), Vector2(lx + side * radius * 0.25, side * radius * 1.15), leg_color, 2.0)

	# Antennae give every enemy an insect read regardless of type.
	var antenna_color := type_color.darkened(0.3)
	for side in [-1.0, 1.0]:
		var base := Vector2(radius * 0.95, side * radius * 0.25)
		var tip := base + Vector2(radius * 0.5, side * radius * 0.55)
		draw_line(base, tip, antenna_color, 2.0)
		draw_circle(tip, 2.0, antenna_color)

	if is_wealthy:
		draw_arc(Vector2.ZERO, radius + 10.0, 0, TAU, 24, Color(1.0, 1.0, 0.6, 0.9), 3.0)


func init(spawn_pixel: Vector2, target_pos: Vector2, cp: CenterPiece = null) -> void:
	center_piece = cp
	global_position = spawn_pixel
	target_position = target_pos
	if is_flanker:
		_setup_flank()


func _setup_flank() -> void:
	var offset := global_position - target_position
	var angle := deg_to_rad(FLANK_ANGLE_DEG) * (1.0 if randf() < 0.5 else -1.0)
	_flank_point = target_position + offset.rotated(angle)


func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = mult
	_slow_timer = duration
	queue_redraw()


func _process(delta: float) -> void:
	if _damage_flash > 0.0:
		_damage_flash = maxf(_damage_flash - delta, 0.0)
		queue_redraw()

	_age += delta
	if is_fast:
		move_speed = lerpf(_base_move_speed, _base_move_speed * ACCEL_MAX_MULT, clampf(_age / ACCEL_SECONDS, 0.0, 1.0))

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0
			queue_redraw()

	if _blocked_by != null:
		if not is_instance_valid(_blocked_by):
			_blocked_by = null
		else:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_blocked_by.take_damage(attack_damage)
				_attack_timer = 1.0 / attack_speed
			velocity = Vector2.ZERO
			move_and_slide()
			return

	var flanking := is_flanker and not _reached_flank
	var current_target := _flank_point if flanking else target_position
	var to_target := current_target - global_position

	if flanking:
		if to_target.length() < 16.0:
			_reached_flank = true
	elif to_target.length() < 8.0:
		_on_reached_center()
		return

	velocity = to_target.normalized() * move_speed * _slow_mult
	move_and_slide()

	if not is_flying:
		for i in get_slide_collision_count():
			var collider := get_slide_collision(i).get_collider()
			if collider is TowerBase:
				_blocked_by = collider
				_attack_timer = 0.0
				break


func take_damage(amount: float) -> void:
	current_health -= amount
	_damage_flash = DAMAGE_FLASH_DURATION
	queue_redraw()
	if current_health <= 0:
		_die()


func _die() -> void:
	SFX.play_death()
	emit_signal("died", global_position)
	_drop_coin()
	queue_free()


func _drop_coin() -> void:
	if coin_scene == null:
		return
	var coin: Coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position
	coin.add_to_group("coins")
	coin.value = coin_value
	coin.essence_value = essence_value
	coin.set_origin(global_position)


func _on_reached_center() -> void:
	if center_piece != null:
		center_piece.take_damage(damage_to_center)
	emit_signal("reached_center")
	queue_free()


signal died(position: Vector2)
signal reached_center
