extends Node2D
class_name CenterPiece

signal hp_changed(current: float, maximum: float)
signal destroyed

@export var max_hp: float = 100.0

var current_hp: float


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	emit_signal("hp_changed", current_hp, max_hp)
	queue_redraw()
	if current_hp <= 0.0:
		emit_signal("destroyed")


func _draw() -> void:
	# HP bar above center hex
	var bar_width := 80.0
	var bar_height := 10.0
	var bar_pos := Vector2(-bar_width / 2.0, -60.0)
	var hp_ratio := current_hp / max_hp

	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.1, 0.1))
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.2, 0.9, 0.3))
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(1.0, 1.0, 1.0, 0.3), false, 1.5)
