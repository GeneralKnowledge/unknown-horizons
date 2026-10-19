class_name BuildFootprint
extends RefCounted


static func origin_tiles(origin: Vector2i, size_x: int, size_y: int) -> Array:
	var tiles: Array = []
	for dx in range(size_x):
		for dy in range(size_y):
			tiles.append(Vector2i(origin.x - dx, origin.y - dy))
	return tiles


static func rect_borders(origin: Vector2i, size_x: int, size_y: int) -> Dictionary:
	var tiles := origin_tiles(origin, size_x, size_y)
	var left := origin.x
	var right := origin.x
	var top := origin.y
	var bottom := origin.y
	for t in tiles:
		var c: Vector2i = t as Vector2i
		left = mini(left, c.x)
		right = maxi(right, c.x)
		top = mini(top, c.y)
		bottom = maxi(bottom, c.y)
	return {"left": left, "right": right, "top": top, "bottom": bottom}


## Tile origins (top-left) for 1×1 placements within building radius (legacy RadiusRect).
static func placement_origins_in_radius(
	origin: Vector2i,
	size_x: int,
	size_y: int,
	radius: int,
	include_self: bool = false
) -> Array:
	var borders := rect_borders(origin, size_x, size_y)
	var left: int = borders.left - radius
	var right: int = borders.right + radius
	var top: int = borders.top - radius
	var bottom: int = borders.bottom + radius
	var out: Array = []
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var pt := Vector2i(x, y)
			if not include_self and _point_in_building_rect(pt, borders):
				continue
			if _distance_point_to_rect_squared(pt, borders) <= radius * radius:
				out.append(pt)
	return out


static func _point_in_building_rect(pt: Vector2i, borders: Dictionary) -> bool:
	return (
		pt.x >= borders.left
		and pt.x <= borders.right
		and pt.y >= borders.top
		and pt.y <= borders.bottom
	)


static func _distance_point_to_rect_squared(pt: Vector2i, borders: Dictionary) -> int:
	var dx := 0
	if pt.x < borders.left:
		dx = borders.left - pt.x
	elif pt.x > borders.right:
		dx = pt.x - borders.right
	var dy := 0
	if pt.y < borders.top:
		dy = borders.top - pt.y
	elif pt.y > borders.bottom:
		dy = borders.bottom - pt.y
	return dx * dx + dy * dy
