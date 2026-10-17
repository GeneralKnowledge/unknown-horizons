class_name BinaryBuildabilityCache
extends RefCounted

## Port of horizons/world/buildability/binarycache.py (entirely-within-area rectangles).

var terrain_cache: TerrainBuildabilityCache
var coords_set: CoordSet = CoordSet.new()
var _row2: CoordSet = CoordSet.new()
var cache: Dictionary = {}


func _init(p_terrain_cache: TerrainBuildabilityCache) -> void:
	terrain_cache = p_terrain_cache
	cache[Vector2i(1, 1)] = coords_set
	for size in TerrainBuildabilitySizes.SIZES:
		if size != Vector2i(1, 1):
			cache[size] = CoordSet.new()
			if size.x != size.y:
				cache[Vector2i(size.y, size.x)] = CoordSet.new()
	_reset_lazy_sets()


func _reset_lazy_sets() -> void:
	cache[Vector2i(4, 4)] = LazyBinaryCacheElement.new(self, 4)
	cache[Vector2i(6, 6)] = LazyBinaryCacheElement.new(self, 6)


static func _extend_set(
	cur_set: CoordSet,
	prev_set: CoordSet,
	prev_set_additions: CoordSet,
	dx: int,
	dy: int
) -> CoordSet:
	var base_set_additions := CoordSet.new()
	for coords in prev_set_additions.keys():
		var prev_coords := Vector2i(coords.x - dx, coords.y - dy)
		if prev_set.has(prev_coords):
			cur_set.add(prev_coords)
			base_set_additions.add(prev_coords)
		var next_coords := Vector2i(coords.x + dx, coords.y + dy)
		if not prev_set_additions.has(next_coords) and prev_set.has(next_coords):
			cur_set.add(coords)
			base_set_additions.add(coords)
	return base_set_additions


static func _reduce_set(cur_set: CoordSet, prev_set_removals: CoordSet, dx: int, dy: int) -> CoordSet:
	var base_set_removals := CoordSet.new()
	for coords in prev_set_removals.keys():
		var prev_coords := Vector2i(coords.x - dx, coords.y - dy)
		if cur_set.has(prev_coords):
			cur_set.discard(prev_coords)
			base_set_removals.add(prev_coords)
		var next_coords := Vector2i(coords.x + dx, coords.y + dy)
		if not prev_set_removals.has(next_coords) and cur_set.has(coords):
			cur_set.discard(coords)
			base_set_removals.add(coords)
	return base_set_removals


func _terrain_has(coords: Vector2i) -> bool:
	return terrain_cache.land_or_coast.has(coords)


func add_area(new_coords_list: Array) -> void:
	var added := CoordSet.new()
	for coords in new_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		if coords_set.has(c):
			continue
		assert(_terrain_has(c))
		coords_set.add(c)
		added.add(c)
	if added.size() == 0:
		return
	var new_row2 := _extend_set(_row2, coords_set, added, 1, 0)
	var new_r2x2 := _extend_set(cache[Vector2i(2, 2)], _row2, new_row2, 0, 1)
	var new_r2x3 := _extend_set(cache[Vector2i(2, 3)], cache[Vector2i(2, 2)], new_r2x2, 0, 1)
	var new_r2x4 := _extend_set(cache[Vector2i(2, 4)], cache[Vector2i(2, 3)], new_r2x3, 0, 1)
	var new_r3x2 := _extend_set(cache[Vector2i(3, 2)], cache[Vector2i(2, 2)], new_r2x2, 1, 0)
	var new_r4x2 := _extend_set(cache[Vector2i(4, 2)], cache[Vector2i(3, 2)], new_r3x2, 1, 0)
	_extend_set(cache[Vector2i(3, 3)], cache[Vector2i(3, 2)], new_r3x2, 0, 1)
	_reset_lazy_sets()


func remove_area(removed_coords_list: Array) -> void:
	for coords in removed_coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		assert(coords_set.has(c))
		coords_set.discard(c)
	# Incremental _reduce_set can drop valid rectangle origins; rebuild from coords_set.
	_rebuild_rectangle_caches()


## Recompute row2 and fixed-size rectangle origin sets from coords_set (after removals).
func _rebuild_rectangle_caches() -> void:
	var remaining: Array = []
	for c in coords_set.keys():
		remaining.append(c)
	coords_set.clear()
	_row2.clear()
	for size in TerrainBuildabilitySizes.SIZES:
		if size == Vector2i(1, 1):
			continue
		var entry = cache[size]
		if entry is LazyBinaryCacheElement:
			continue
		(entry as CoordSet).clear()
	if remaining.is_empty():
		_reset_lazy_sets()
		return
	add_area(remaining)


func cache_set_for_size(size: Vector2i) -> CoordSet:
	var entry = cache[size]
	if entry is LazyBinaryCacheElement:
		return entry.ensure_ready()
	return entry as CoordSet


func can_place(origin: Vector2i, size: Vector2i) -> bool:
	return cache_set_for_size(size).has(origin)
