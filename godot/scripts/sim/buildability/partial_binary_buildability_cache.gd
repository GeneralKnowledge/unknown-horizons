class_name PartialBinaryBuildabilityCache
extends RefCounted

## Port of horizons/world/buildability/partialbinarycache.py

var terrain_cache: Variant
var coords_set: CoordSet = CoordSet.new()
var _row2: CoordSet = CoordSet.new()
var cache: Dictionary = {} # Vector2i size key -> CoordSet


func _init(p_terrain_cache: Variant) -> void:
	terrain_cache = p_terrain_cache
	var sizes: Dictionary = {}
	for size in TerrainBuildabilitySizes.SIZES:
		sizes[size] = true
	for extra in [Vector2i(3, 4), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 6)]:
		sizes[extra] = true
	cache[Vector2i(1, 1)] = coords_set
	for size in sizes.keys():
		if size != Vector2i(1, 1):
			cache[size] = CoordSet.new()
			if size.x != size.y:
				cache[Vector2i(size.y, size.x)] = CoordSet.new()


static func _extend_set(
	cur_set: CoordSet,
	prev_set_additions: CoordSet,
	dx: int,
	dy: int
) -> CoordSet:
	var base_set_additions := CoordSet.new()
	for coords in prev_set_additions.keys():
		var prev_coords := Vector2i(coords.x - dx, coords.y - dy)
		if not cur_set.has(prev_coords):
			cur_set.add(prev_coords)
			base_set_additions.add(prev_coords)
		var next_coords := Vector2i(coords.x + dx, coords.y + dy)
		if not prev_set_additions.has(next_coords) and not cur_set.has(coords):
			cur_set.add(coords)
			base_set_additions.add(coords)
	return base_set_additions


static func _reduce_set(
	cur_set: CoordSet,
	prev_set: CoordSet,
	prev_set_removals: CoordSet,
	dx: int,
	dy: int
) -> CoordSet:
	var base_set_removals := CoordSet.new()
	for coords in prev_set_removals.keys():
		var prev_coords := Vector2i(coords.x - dx, coords.y - dy)
		if not prev_set.has(prev_coords):
			cur_set.discard(prev_coords)
			base_set_removals.add(prev_coords)
		var next_coords := Vector2i(coords.x + dx, coords.y + dy)
		if not prev_set_removals.has(next_coords) and not prev_set.has(next_coords):
			cur_set.discard(coords)
			base_set_removals.add(coords)
	return base_set_removals


func _land_has(coords: Vector2i) -> bool:
	if terrain_cache.land_or_coast is CoordSet:
		return terrain_cache.land_or_coast.has(coords)
	if terrain_cache.land_or_coast is Dictionary:
		return terrain_cache.land_or_coast.has(coords)
	for c in terrain_cache.land_or_coast:
		var v: Vector2i = c if c is Vector2i else Vector2i(c[0], c[1])
		if v == coords:
			return true
	return false


func add_area(new_coords_list: Array) -> void:
	for coords in new_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		assert(not coords_set.has(c))
		assert(_land_has(c))
		coords_set.add(c)
	var added := CoordSet.new()
	for coords in new_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		added.add(c)
	var new_row2 := _extend_set(_row2, added, 1, 0)
	var new_r2x2 := _extend_set(cache[Vector2i(2, 2)], new_row2, 0, 1)
	var new_r2x3 := _extend_set(cache[Vector2i(2, 3)], new_r2x2, 0, 1)
	var new_r2x4 := _extend_set(cache[Vector2i(2, 4)], new_r2x3, 0, 1)
	var new_r3x2 := _extend_set(cache[Vector2i(3, 2)], new_r2x2, 1, 0)
	var new_r4x2 := _extend_set(cache[Vector2i(4, 2)], new_r3x2, 1, 0)
	var new_r3x3 := _extend_set(cache[Vector2i(3, 3)], new_r3x2, 0, 1)
	var new_r3x4 := _extend_set(cache[Vector2i(3, 4)], new_r3x3, 0, 1)
	var new_r4x4 := _extend_set(cache[Vector2i(4, 4)], new_r3x4, 1, 0)
	var new_r4x5 := _extend_set(cache[Vector2i(4, 5)], new_r4x4, 0, 1)
	var new_r5x5 := _extend_set(cache[Vector2i(5, 5)], new_r4x5, 1, 0)
	var new_r5x6 := _extend_set(cache[Vector2i(5, 6)], new_r5x5, 0, 1)
	_extend_set(cache[Vector2i(6, 6)], new_r5x6, 1, 0)


func remove_area(removed_coords_list: Array) -> void:
	for coords in removed_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		assert(coords_set.has(c))
		assert(_land_has(c))
		coords_set.discard(c)
	var removed := CoordSet.new()
	for coords in removed_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		removed.add(c)
	var removed_row2 := _reduce_set(_row2, coords_set, removed, 1, 0)
	var removed_r2x2 := _reduce_set(cache[Vector2i(2, 2)], _row2, removed_row2, 0, 1)
	var removed_r2x3 := _reduce_set(cache[Vector2i(2, 3)], cache[Vector2i(2, 2)], removed_r2x2, 0, 1)
	var removed_r2x4 := _reduce_set(cache[Vector2i(2, 4)], cache[Vector2i(2, 3)], removed_r2x3, 0, 1)
	var removed_r3x2 := _reduce_set(cache[Vector2i(3, 2)], cache[Vector2i(2, 2)], removed_r2x2, 1, 0)
	var removed_r4x2 := _reduce_set(cache[Vector2i(4, 2)], cache[Vector2i(3, 2)], removed_r3x2, 1, 0)
	var removed_r3x3 := _reduce_set(cache[Vector2i(3, 3)], cache[Vector2i(3, 2)], removed_r3x2, 0, 1)
	var removed_r3x4 := _reduce_set(cache[Vector2i(3, 4)], cache[Vector2i(3, 3)], removed_r3x3, 0, 1)
	var removed_r4x4 := _reduce_set(cache[Vector2i(4, 4)], cache[Vector2i(3, 4)], removed_r3x4, 1, 0)
	var removed_r4x5 := _reduce_set(cache[Vector2i(4, 5)], cache[Vector2i(4, 4)], removed_r4x4, 0, 1)
	var removed_r5x5 := _reduce_set(cache[Vector2i(5, 5)], cache[Vector2i(4, 5)], removed_r4x5, 1, 0)
	var removed_r5x6 := _reduce_set(cache[Vector2i(5, 6)], cache[Vector2i(5, 5)], removed_r5x5, 0, 1)
	_reduce_set(cache[Vector2i(6, 6)], cache[Vector2i(5, 6)], removed_r5x6, 1, 0)
