class_name PathData
extends Resource

enum Type {
	STRAIGHT,    # A* direct to center
	ENCIRCLE,    # orbit outer ring, then rush
	FLANK,       # approach from a different angle
}

@export var path_type: Type = Type.STRAIGHT
@export var spawn_hex: Vector2i = Vector2i.ZERO
@export var points: Array[Vector2] = []


static func make(type: Type, spawn: Vector2i, pixel_points: Array[Vector2]) -> PathData:
	var pd := PathData.new()
	pd.path_type = type
	pd.spawn_hex = spawn
	pd.points = pixel_points
	return pd
