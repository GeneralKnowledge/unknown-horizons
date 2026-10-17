class_name BuildFootprint
extends RefCounted


static func origin_tiles(origin: Vector2i, size_x: int, size_y: int) -> Array:
	var tiles: Array = []
	for dx in range(size_x):
		for dy in range(size_y):
			tiles.append(Vector2i(origin.x - dx, origin.y - dy))
	return tiles
