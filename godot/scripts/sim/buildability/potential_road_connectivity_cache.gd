class_name PotentialRoadConnectivityCache
extends RefCounted

## Subset of legacy road connectivity (E3): tracks road tiles and network adjacency for trails.

var _road_tiles: CoordSet = CoordSet.new()


func set_roads(tiles: CoordSet) -> void:
	_road_tiles = tiles


func sync_from_island(island: Island) -> void:
	var tiles := CoordSet.new()
	for coords in island.road_tiles.keys():
		tiles.add(coords if coords is Vector2i else Vector2i(coords[0], coords[1]))
	set_roads(tiles)


func is_road(coords: Vector2i) -> bool:
	return _road_tiles.has(coords)


func trail_footprint_connects(island: Island, footprint: Array, settlement: Settlement) -> bool:
	sync_from_island(island)
	for tile in footprint:
		var at: Vector2i = tile if tile is Vector2i else Vector2i(tile[0], tile[1])
		for n in _neighbors(at):
			if island.is_road(n) or _is_network_building_tile(island, n):
				return true
	return false


static func _neighbors(c: Vector2i) -> Array:
	return [
		Vector2i(c.x + 1, c.y),
		Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1),
		Vector2i(c.x, c.y - 1),
	]


static func _is_network_building_tile(island: Island, coords: Vector2i) -> bool:
	return island.occupied_tiles.has(coords)
