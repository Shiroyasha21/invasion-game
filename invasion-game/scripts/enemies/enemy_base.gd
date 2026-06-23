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
	var radius: float
	if is_flying:
		_draw_dragonfly()
		radius = 16.0
	elif is_fast:
		_draw_wasp()
		radius = 18.0
	elif is_flanker:
		_draw_spider()
		radius = 19.0
	elif is_tanky:
		_draw_beetle()
		radius = 27.0
	else:
		_draw_ant()
		radius = 20.0

	# Marks a "wealthy" enemy — drops a much bigger coin/essence bonus.
	# Pulses instead of sitting as a flat ring, to read as treasure-shiny
	# rather than an arbitrary outline.
	if is_wealthy:
		var pulse := (sin(_age * 5.0) + 1.0) / 2.0
		draw_arc(Vector2.ZERO, radius + 8.0 + pulse * 4.0, 0, TAU, 24, Color(1.0, 1.0, 0.6, 0.7 + pulse * 0.3), 3.0)


func _fill_color(base_color: Color) -> Color:
	var fill := Color(1.0, 0.85, 0.1) if is_wealthy else base_color
	if _slow_timer > 0.0:
		fill = fill.lerp(Color(0.2, 0.7, 0.3), 0.6)
	fill = fill.lerp(Color.WHITE, _damage_flash / DAMAGE_FLASH_DURATION)
	return fill


# The body rotates to face the centerpiece, so counter-rotate the shadow to
# keep it pointing in a consistent world-down direction.
func _draw_shadow(radius: float, offset: Vector2, scale_y: float) -> void:
	draw_set_transform(offset.rotated(-rotation), -rotation, Vector2(1.0, scale_y))
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.0, 0.0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_antennae(radius: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var base := Vector2(radius * 0.95, side * radius * 0.25)
		var tip := base + Vector2(radius * 0.5, side * radius * 0.55)
		draw_line(base, tip, color, 2.0)
		draw_circle(tip, 2.0, color)


func _draw_legs(radius: float, color: Color, count: int = 3) -> void:
	for side in [-1.0, 1.0]:
		for i in count:
			var lx := -radius * 0.5 + i * radius * 0.45
			draw_line(Vector2(lx, side * radius * 0.55), Vector2(lx + side * radius * 0.25, side * radius * 1.15), color, 2.0)


# Plain six-legged crawler — the baseline "normal" threat.
func _draw_ant() -> void:
	var radius := 20.0
	var base_color := Color(0.85, 0.2, 0.15)
	_draw_shadow(radius, Vector2(3.0, radius * 0.4), 0.55)
	var fill := _fill_color(base_color)

	draw_set_transform(Vector2(-radius * 0.2, 0), 0.0, Vector2(1.25, 0.85))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(radius * 0.75, 0), radius * 0.55, fill.darkened(0.12))
	draw_arc(Vector2(-radius * 0.2, 0), radius * 1.25, 0, TAU, 18, base_color.lightened(0.3), 2.0)

	_draw_legs(radius, base_color.darkened(0.45), 3)
	_draw_antennae(radius, base_color.darkened(0.3))


# Slender, striped, pointed tail — reads as quick and aggressive.
func _draw_wasp() -> void:
	var radius := 18.0
	var base_color := Color(1.0, 0.62, 0.05)
	_draw_shadow(radius, Vector2(3.0, radius * 0.4), 0.5)
	var fill := _fill_color(base_color)

	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(-radius * 0.1, side * radius * 0.5), 0.0, Vector2(1.8, 0.5))
		draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 1.0, 1.0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2(-radius * 0.35, 0), 0.0, Vector2(1.5, 0.65))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tail := PackedVector2Array([
		Vector2(-radius * 1.6, -radius * 0.25), Vector2(-radius * 2.2, 0), Vector2(-radius * 1.6, radius * 0.25),
	])
	draw_colored_polygon(tail, fill.darkened(0.1))

	for i in 2:
		var lx := -radius * 0.7 + i * radius * 0.5
		draw_line(Vector2(lx, -radius * 0.55), Vector2(lx, radius * 0.55), Color(0.15, 0.1, 0.05), 2.5)

	draw_circle(Vector2(radius * 0.85, 0), radius * 0.45, fill.darkened(0.12))
	_draw_legs(radius, base_color.darkened(0.5), 3)
	_draw_antennae(radius, base_color.darkened(0.3))


# Broad armored shell with a crease and spots — reads as slow and tough.
func _draw_beetle() -> void:
	var radius := 27.0
	var base_color := Color(0.45, 0.32, 0.08)
	_draw_shadow(radius, Vector2(4.0, radius * 0.45), 0.55)
	var fill := _fill_color(base_color)

	draw_set_transform(Vector2(-radius * 0.1, 0), 0.0, Vector2(1.15, 0.95))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(radius * 0.7, 0), radius * 0.4, fill.darkened(0.15))
	draw_arc(Vector2(-radius * 0.1, 0), radius * 1.15, 0, TAU, 20, base_color.lightened(0.25), 2.0)

	draw_line(Vector2(-radius * 0.9, 0), Vector2(radius * 0.5, 0), base_color.darkened(0.5), 2.0)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(-radius * 0.3, side * radius * 0.4), radius * 0.12, base_color.darkened(0.4))
		draw_circle(Vector2(radius * 0.15, side * radius * 0.3), radius * 0.1, base_color.darkened(0.4))

	_draw_legs(radius, base_color.darkened(0.5), 3)
	_draw_antennae(radius * 0.7, base_color.darkened(0.3))


# Round-bodied, eight-legged, no antennae — visually distinct from the
# insects, fitting its skittish arc-then-commit movement.
func _draw_spider() -> void:
	var radius := 19.0
	var base_color := Color(0.55, 0.2, 0.65)
	_draw_shadow(radius, Vector2(3.0, radius * 0.4), 0.5)
	var fill := _fill_color(base_color)

	draw_circle(Vector2(-radius * 0.3, 0), radius, fill)
	draw_circle(Vector2(radius * 0.55, 0), radius * 0.55, fill.darkened(0.1))
	draw_arc(Vector2(-radius * 0.3, 0), radius * 1.05, 0, TAU, 18, base_color.lightened(0.3), 2.0)

	var leg_color := base_color.darkened(0.5)
	for side in [-1.0, 1.0]:
		for i in 4:
			var t := float(i) / 3.0
			var base_pt := Vector2(-radius * 0.5 + t * radius * 0.9, side * radius * 0.3)
			var tip := base_pt + Vector2(-radius * 0.3 + t * radius * 0.6, side * radius * 1.3)
			draw_line(base_pt, tip, leg_color, 2.0)


# Slender body, big translucent wings, no legs — the only one towers can't
# physically block.
func _draw_dragonfly() -> void:
	var radius := 16.0
	var base_color := Color(0.25, 0.75, 0.95)
	_draw_shadow(radius, Vector2(5.0, radius * 0.65), 0.4)
	var fill := _fill_color(base_color)

	# Big, clearly-visible wings — the main visual cue that this is an air
	# unit towers can't physically block.
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(-radius * 0.1, side * radius * 0.45), deg_to_rad(side * -20.0), Vector2(3.2, 0.7))
		draw_circle(Vector2(radius * 0.6, 0), radius * 0.7, Color(1.0, 1.0, 1.0, 0.45))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_set_transform(Vector2(-radius * 0.6, side * radius * 0.35), deg_to_rad(side * -15.0), Vector2(2.6, 0.6))
		draw_circle(Vector2(radius * 0.3, 0), radius * 0.55, Color(1.0, 1.0, 1.0, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2(-radius * 0.3, 0), 0.0, Vector2(1.8, 0.45))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_circle(Vector2(radius * 0.85, 0), radius * 0.5, fill.darkened(0.1))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(radius * 0.95, side * radius * 0.22), radius * 0.22, Color(0.05, 0.1, 0.15))


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
	rotation = (target_position - global_position).angle()

	if _damage_flash > 0.0:
		_damage_flash = maxf(_damage_flash - delta, 0.0)
		queue_redraw()

	_age += delta
	if is_fast:
		move_speed = lerpf(_base_move_speed, _base_move_speed * ACCEL_MAX_MULT, clampf(_age / ACCEL_SECONDS, 0.0, 1.0))
	if is_wealthy:
		queue_redraw()

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
	# Coins and Essence are visually distinct pickups (coin vs. chest), so
	# they drop as two separate items instead of one node carrying both.
	if coin_value > 0:
		_spawn_pickup(coin_value, 0, false, Vector2(-6.0, 0))
	if essence_value > 0:
		_spawn_pickup(0, essence_value, true, Vector2(6.0, 0))


func _spawn_pickup(coin_amount: int, essence_amount: int, chest: bool, offset: Vector2) -> void:
	var coin: Coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	var pos := global_position + offset
	coin.global_position = pos
	coin.add_to_group("coins")
	coin.value = coin_amount
	coin.essence_value = essence_amount
	coin.is_chest = chest
	coin.set_origin(pos)


func _on_reached_center() -> void:
	if center_piece != null:
		center_piece.take_damage(damage_to_center)
	emit_signal("reached_center")
	queue_free()


signal died(position: Vector2)
signal reached_center
