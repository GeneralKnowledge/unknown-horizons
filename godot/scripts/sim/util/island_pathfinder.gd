class_name IslandPathfinder
extends RefCounted

## Minimal grid BFS on island land tiles (horizons pathfinder subset).


static func find_path(island: Island, from: Vector2i, to: Vector2i, max_steps: int = 256) -> Array:
	if from == to:
		return [from]
	var frontier: Array = [from]
	var came_from: Dictionary = {from: null}
	var steps := 0
	while not frontier.is_empty() and steps < max_steps:
		steps += 1
		var next: Array = []
		for cell in frontier:
			for n in _neighbors(cell):
				if came_from.has(n):
					continue
				if not _walkable(island, n):
					continue
				came_from[n] = cell
				if n == to:
					return _reconstruct(came_from, to)
				next.append(n)
		frontier = next
	return []


static func _neighbors(c: Vector2i) -> Array:
	return [Vector2i(c.x + 1, c.y), Vector2i(c.x - 1, c.y), Vector2i(c.x, c.y + 1), Vector2i(c.x, c.y - 1)]


static func _walkable(island: Island, c: Vector2i) -> bool:
	if not island.ground_map.has(c):
		return false
	if island.is_road(c):
		return true
	if not island.is_land(c):
		return false
	return true


static func _reconstruct(came_from: Dictionary, to: Vector2i) -> Array:
	var path: Array = [to]
	var cur = to
	while came_from[cur] != null:
		cur = came_from[cur]
		path.push_front(cur)
	return path
