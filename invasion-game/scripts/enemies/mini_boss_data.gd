class_name MiniBossData
extends Resource

enum AttackPattern { RANGED, SLAM }

@export var id: String = "mboss_1"
@export var display_name: String = "Brute"
@export var base_hp: float = 300.0
@export var base_damage: float = 20.0
@export var base_speed: float = 50.0
@export var hp_growth_rate: float = 0.15  # extra fraction of base_hp added per elapsed minute
@export var damage_growth_rate: float = 0.10  # extra fraction of base_damage added per elapsed minute
@export var attack_pattern: AttackPattern = AttackPattern.SLAM
@export var attack_range: float = 140.0
@export var attack_interval: float = 2.0
@export var splash_radius: float = 80.0
@export var visual_scale: float = 1.8
@export var min_minute: float = 0.0
@export var max_minute: float = 999.0
@export var coin_reward: int = 50
