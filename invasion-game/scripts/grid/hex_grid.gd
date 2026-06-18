# Pointy-top axial hex coordinate math.
# All grid logic references this — do not put game logic here.

class_name HexGrid

const SQRT3 := sqrt(3.0)

# Axial directions for pointy-top: N, NE, SE, S, SW, NW
const DIRECTIONS := [
	Vector2i(0, -1),  # N
	Vector2i(1, -1),  # NE
	Vector2i(1, 0),   # SE
	Vector2i(0, 1),   # S
	Vector2i(-1, 1),  # SW
	Vector2i(-1, 0),  # NW
]

const DIR_NAMES := ["N", "NE", "SE", "S", "SW", "NW"]


static func hex_to_pixel(hex: Vector2i, size: float) -> Vector2:
	var x := size * SQRT3 * (hex.x + hex.y * 0.5)
	var y := size * 1.5 * hex.y
	return Vector2(x, y)


static func pixel_to_hex(pos: Vector2, size: float) -> Vector2i:
	var q := (pos.x * SQRT3 / 3.0 - pos.y / 3.0) / size
	var r := pos.y * 2.0 / 3.0 / size
	return axial_round(Vector2(q, r))


static func axial_round(frac: Vector2) -> Vector2i:
	var s := -frac.x - frac.y
	var rx := roundi(frac.x)
	var ry := roundi(frac.y)
	var rs := roundi(s)
	var x_diff := absf(rx - frac.x)
	var y_diff := absf(ry - frac.y)
	var s_diff := absf(rs - s)
	if x_diff > y_diff and x_diff > s_diff:
		rx = -ry - rs
	elif y_diff > s_diff:
		ry = -rx - rs
	return Vector2i(rx, ry)


static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := b - a
	return int((absi(d.x) + absi(d.x + d.y) + absi(d.y)) / 2)


static func neighbor(hex: Vector2i, dir: int) -> Vector2i:
	return hex + DIRECTIONS[dir]


static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		result.append(hex + dir)
	return result


# Returns all hexes in a ring at given radius from center.
static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	if radius == 0:
		results.append(center)
		return results
	var hex := center + DIRECTIONS[4] * radius  # start at SW * radius
	for i in 6:
		for _j in radius:
			results.append(hex)
			hex = neighbor(hex, i)
	return results


# Returns all hexes within radius (inclusive).
static func filled_circle(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for r in range(radius + 1):
		results.append_array(ring(center, r))
	return results


# Returns the 6 corner pixel positions of a hex (for drawing).
static func corners(center_px: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * i - 30.0)  # pointy-top offset
		pts.append(center_px + Vector2(cos(angle), sin(angle)) * size)
	return pts
