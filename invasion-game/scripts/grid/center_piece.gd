extends Node2D
class_name CenterPiece

signal hp_changed(current: float, maximum: float)
signal destroyed

@export var max_hp: float = 100.0

var current_hp: float
var _growth_stage: int = 0  # 0 = bare, 1 = flowering, 2 = fruiting


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	emit_signal("hp_changed", current_hp, max_hp)
	queue_redraw()
	if current_hp <= 0.0:
		emit_signal("destroyed")


# Purely cosmetic, driven by how far through the run we are — no gameplay
# effect. 0..0.33 = bare tree, 0.33..0.66 = flowers, 0.66..1.0 = fruit.
func set_run_progress(t: float) -> void:
	var stage := 0
	if t >= 0.66:
		stage = 2
	elif t >= 0.33:
		stage = 1
	if stage != _growth_stage:
		_growth_stage = stage
		queue_redraw()


func _draw() -> void:
	var hp_ratio := current_hp / max_hp

	# Shadow, anchored at the trunk's base
	draw_set_transform(Vector2(6.0, 6.0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 36.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Trunk
	var trunk_w := 12.0
	var trunk_h := 30.0
	draw_rect(Rect2(Vector2(-trunk_w / 2, -trunk_h), Vector2(trunk_w, trunk_h)), Color(0.45, 0.28, 0.12))

	# Canopy — wilts toward brown as HP drops instead of showing an HP bar.
	var canopy_r := 32.0
	var canopy_y := -trunk_h - canopy_r * 0.5
	var green := Color(0.15, 0.65, 0.18).lerp(Color(0.4, 0.3, 0.12), 1.0 - hp_ratio)
	draw_circle(Vector2(0, canopy_y), canopy_r, green)

	if _growth_stage >= 1:
		_draw_flowers(canopy_y, canopy_r)
	if _growth_stage >= 2:
		_draw_fruit(canopy_y, canopy_r)


func _draw_flowers(canopy_y: float, canopy_r: float) -> void:
	var positions := [
		Vector2(-canopy_r * 0.5, canopy_y - canopy_r * 0.3),
		Vector2(canopy_r * 0.4, canopy_y - canopy_r * 0.5),
		Vector2(-canopy_r * 0.1, canopy_y + canopy_r * 0.4),
		Vector2(canopy_r * 0.55, canopy_y + canopy_r * 0.1),
		Vector2(-canopy_r * 0.6, canopy_y + canopy_r * 0.2),
	]
	for pos in positions:
		draw_circle(pos, 5.0, Color(1.0, 0.75, 0.85))
		draw_circle(pos, 2.5, Color(1.0, 0.95, 0.4))


func _draw_fruit(canopy_y: float, canopy_r: float) -> void:
	var positions := [
		Vector2(-canopy_r * 0.45, canopy_y + canopy_r * 0.5),
		Vector2(canopy_r * 0.5, canopy_y + canopy_r * 0.45),
		Vector2(canopy_r * 0.05, canopy_y + canopy_r * 0.65),
	]
	for pos in positions:
		draw_circle(pos, 6.5, Color(0.85, 0.15, 0.15))
		draw_circle(pos - Vector2(2.0, 2.0), 2.0, Color(1.0, 0.5, 0.4, 0.6))
