extends Node2D
class_name CenterPiece

signal hp_changed(current: float, maximum: float)
signal destroyed
signal level_up(new_level: int)

@export var max_hp: float = 100.0
@export var hp_per_level: float = 50.0

var current_hp: float
var level: int = 1


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	emit_signal("hp_changed", current_hp, max_hp)
	queue_redraw()
	if current_hp <= 0.0:
		emit_signal("destroyed")


# Called by the future meta-progression system when the player spends
# currency to grow the tree between runs.
func grow() -> void:
	level += 1
	max_hp += hp_per_level
	current_hp = max_hp
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("level_up", level)
	queue_redraw()


func _draw() -> void:
	var hp_ratio := current_hp / max_hp
	var scale_factor := 0.7 + level * 0.15

	# Shadow, anchored at the trunk's base
	var shadow_radius := 36.0 * scale_factor
	draw_set_transform(Vector2(6.0, 6.0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.0, 0.0, 0.0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Trunk
	var trunk_w := 12.0 * scale_factor
	var trunk_h := 30.0 * scale_factor
	draw_rect(Rect2(Vector2(-trunk_w / 2, -trunk_h), Vector2(trunk_w, trunk_h)),
		Color(0.45, 0.28, 0.12))

	# Canopy layers (more as level increases)
	var layers := mini(level, 4)
	for i in layers:
		var r := (28.0 + i * 8.0) * scale_factor
		var y_offset := (-trunk_h - r * 0.5 + i * 10.0 * scale_factor)
		var green := Color(0.1, 0.6, 0.15).lerp(Color(0.3, 0.9, 0.2), float(i) / 4.0)
		draw_circle(Vector2(0, y_offset), r, green)

	# HP bar
	var bar_w := 80.0
	var bar_pos := Vector2(-bar_w / 2.0, -80.0 * scale_factor)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 10)), Color(0.2, 0.1, 0.1))
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, 10)), Color(0.2, 0.9, 0.3))
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 10)), Color(1.0, 1.0, 1.0, 0.3), false, 1.5)
