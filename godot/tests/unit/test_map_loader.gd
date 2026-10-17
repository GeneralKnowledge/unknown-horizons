extends GutTest


func test_list_maps_includes_bundled_manifest() -> void:
	var maps: Array = MapLoader.list_maps()
	assert_gt(maps.size(), 0)
	var ids: Array = []
	for entry in maps:
		ids.append(str(entry.get("id", "")))
	assert_true("test_island_20x20" in ids)


func test_load_ground_unknown_id_falls_back() -> void:
	var ground: Dictionary = MapLoader.load_ground_for_map("nonexistent_map_id")
	assert_gt(ground.size(), 0)
