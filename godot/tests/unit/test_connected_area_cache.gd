extends GutTest


func _coords_dict(area: Dictionary) -> Dictionary:
	return area.duplicate()


func test_connected_area_lifecycle() -> void:
	var cache := ConnectedAreaCache.new()
	assert_eq(0, cache.areas.size())

	cache.add_area([Vector2i(0, 0), Vector2i(1, 1)])
	assert_eq(2, cache.areas.size())
	var id00 := int(cache.area_numbers[Vector2i(0, 0)])
	var id11 := int(cache.area_numbers[Vector2i(1, 1)])
	assert_eq(1, _coords_dict(cache.areas[id00]).size())
	assert_eq(1, _coords_dict(cache.areas[id11]).size())

	cache.add_area([Vector2i(1, 4), Vector2i(1, 3), Vector2i(1, 2)])
	assert_eq(2, cache.areas.size())
	id11 = int(cache.area_numbers[Vector2i(1, 1)])
	assert_eq(4, _coords_dict(cache.areas[id11]).size())

	cache.add_area([Vector2i(0, 1)])
	assert_eq(1, cache.areas.size())
	id00 = int(cache.area_numbers[Vector2i(0, 0)])
	assert_eq(6, _coords_dict(cache.areas[id00]).size())

	cache.remove_area([Vector2i(0, 1)])
	assert_eq(2, cache.areas.size())

	cache.remove_area([Vector2i(0, 0)])
	assert_false(cache.area_numbers.has(Vector2i(0, 0)))
	assert_eq(1, cache.areas.size())

	cache.remove_area([Vector2i(1, 2), Vector2i(1, 3)])
	assert_eq(2, cache.areas.size())

	cache.remove_area([Vector2i(1, 1), Vector2i(1, 4)])
	assert_eq(0, cache.areas.size())
