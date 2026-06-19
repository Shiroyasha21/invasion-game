class_name TowerData
extends Resource

enum TargetMode { NEAREST, FARTHEST }

@export var id: String = "arrow"
@export var display_name: String = "Arrow"
@export var cost: int = 10
@export var attack_range: float = 200.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var max_hp: float = 50.0
@export var splash_radius: float = 0.0
@export var body_color: Color = Color(0.4, 0.5, 0.6)
@export var body_radius: float = 28.0
@export var barrel_length: float = 30.0
@export var projectile_color: Color = Color(1.0, 0.9, 0.2)
@export var projectile_radius: float = 6.0
@export var projectile_speed: float = 400.0
@export var projectile_is_streak: bool = false
@export var target_mode: TargetMode = TargetMode.NEAREST
