class_name PotentialRoadConnectivityCache
extends RefCounted

## Placeholder for legacy road connectivity (E3). Roads are tracked on `Island.road_tiles` today.

var _road_tiles: CoordSet = CoordSet.new()


func set_roads(tiles: CoordSet) -> void:
	_road_tiles = tiles


func is_road(coords: Vector2i) -> bool:
	return _road_tiles.has(coords)
