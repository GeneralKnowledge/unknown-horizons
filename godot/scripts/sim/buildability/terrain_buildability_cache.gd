class_name TerrainBuildabilityCache
extends RefCounted

## Port subset of horizons/world/buildability/terraincache.py (LAND + LAND_AND_COAST).

var land: CoordSet = CoordSet.new()
var coast: CoordSet = CoordSet.new()
var land_or_coast: CoordSet = CoordSet.new()
var land_cache: Dictionary = {} # Vector2i size -> CoordSet origins
var land_and_coast_cache: Dictionary = {} # Vector2i size -> CoordSet origins


func _init(p_land: CoordSet, p_coast: CoordSet = null) -> void:
	land = p_land.duplicate_set()
	coast = p_coast.duplicate_set() if p_coast != null else CoordSet.new()
	land_or_coast = land.duplicate_set()
	for c in coast.keys():
		land_or_coast.add(c)
	_build_land_cache()
	_build_land_and_coast_cache()


func _build_land_cache() -> void:
	land_cache.clear()
	land_cache[Vector2i(1, 1)] = land_or_coast.duplicate_set()
	for size in TerrainBuildabilitySizes.SIZES:
		if size == Vector2i(1, 1):
			continue
		var set := CoordSet.new()
		var alt := CoordSet.new()
		for tile in land.keys():
			if _footprint_inside(land, tile, size):
				set.add(tile)
				if size.x != size.y:
					alt.add(tile)
		land_cache[size] = set
		if size.x != size.y:
			land_cache[Vector2i(size.y, size.x)] = alt


func _build_land_and_coast_cache() -> void:
	land_and_coast_cache.clear()
	for size in [Vector2i(2, 2), Vector2i(3, 3), Vector2i(2, 3), Vector2i(2, 4)]:
		var set := CoordSet.new()
		for tile in land_or_coast.keys():
			if _footprint_inside(land_or_coast, tile, size) and _footprint_spans_land_and_coast(tile, size):
				set.add(tile)
		land_and_coast_cache[size] = set
		if size.x != size.y:
			land_and_coast_cache[Vector2i(size.y, size.x)] = set.duplicate_set()


static func _footprint_inside(terrain: CoordSet, origin: Vector2i, size: Vector2i) -> bool:
	for c in BuildFootprint.origin_tiles(origin, size.x, size.y):
		if not terrain.has(c):
			return false
	return true


func _footprint_spans_land_and_coast(origin: Vector2i, size: Vector2i) -> bool:
	var on_land := false
	var on_coast := false
	for c in BuildFootprint.origin_tiles(origin, size.x, size.y):
		if land.has(c):
			on_land = true
		if coast.has(c):
			on_coast = true
	return on_land and on_coast


func can_place_land(origin: Vector2i, size: Vector2i) -> bool:
	return _cache_has(land_cache, origin, size)


func can_place_land_and_coast(origin: Vector2i, size: Vector2i) -> bool:
	return _cache_has(land_and_coast_cache, origin, size)


func can_place_for_requirement(requirement: int, origin: Vector2i, size: Vector2i) -> bool:
	if requirement == TerrainRequirement.LAND_AND_COAST:
		return can_place_land_and_coast(origin, size)
	return can_place_land(origin, size)


static func _cache_has(cache: Dictionary, origin: Vector2i, size: Vector2i) -> bool:
	var key := size
	if not cache.has(key):
		key = Vector2i(size.y, size.x)
	if not cache.has(key):
		return false
	return (cache[key] as CoordSet).has(origin)
