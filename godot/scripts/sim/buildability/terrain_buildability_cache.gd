class_name TerrainBuildabilityCache
extends RefCounted

## Simplified port: LAND placements for constructible tiles.

var land_or_coast: CoordSet = CoordSet.new()
var land_cache: Dictionary = {} # Vector2i size -> CoordSet


func _init(land_tiles: CoordSet) -> void:
	land_or_coast = land_tiles.duplicate_set()
	land_cache[Vector2i(1, 1)] = land_or_coast.duplicate_set()
	for size in TerrainBuildabilitySizes.SIZES:
		if size == Vector2i(1, 1):
			continue
		var set := CoordSet.new()
		var alt := CoordSet.new()
		for tile in land_or_coast.keys():
			if _footprint_inside(land_or_coast, tile, size):
				set.add(tile)
				if size.x != size.y:
					alt.add(tile)
		land_cache[size] = set
		if size.x != size.y:
			land_cache[Vector2i(size.y, size.x)] = alt


static func _footprint_inside(land: CoordSet, origin: Vector2i, size: Vector2i) -> bool:
	for c in BuildFootprint.origin_tiles(origin, size.x, size.y):
		if not land.has(c):
			return false
	return true


func can_place_land(origin: Vector2i, size: Vector2i) -> bool:
	var key := size
	if not land_cache.has(key):
		key = Vector2i(size.y, size.x)
	if not land_cache.has(key):
		return false
	return land_cache[key].has(origin)
