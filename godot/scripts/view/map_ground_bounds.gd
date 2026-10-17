class_name MapGroundBounds
extends RefCounted


static func compute_grid_aabb(island: Island) -> Rect2i:
	if island == null or island.ground_map.is_empty():
		return Rect2i()
	var min_x := 999999
	var min_y := 999999
	var max_x := -999999
	var max_y := -999999
	for coords in island.ground_map.keys():
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func compute_screen_aabb(map_view: MapView) -> Rect2:
	if map_view == null or map_view.island == null:
		return Rect2()
	var grid := compute_grid_aabb(map_view.island)
	if grid.size == Vector2i.ZERO:
		return Rect2()
	var p1 := map_view.grid_to_screen(grid.position)
	var p2 := map_view.grid_to_screen(grid.position + grid.size)
	var min_p := Vector2(minf(p1.x, p2.x), minf(p1.y, p2.y))
	var max_p := Vector2(maxf(p1.x, p2.x), maxf(p1.y, p2.y))
	return Rect2(min_p, max_p - min_p)
