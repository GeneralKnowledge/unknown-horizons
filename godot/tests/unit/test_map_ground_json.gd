extends GutTest


func test_map_loader_reads_exported_ground_json() -> void:
	var maps: Array = MapLoader.list_maps()
	var found := false
	for entry in maps:
		if str(entry.get("loader", "")) != "ground_json":
			continue
		found = true
		var map_id: String = str(entry.get("id", ""))
		var ground: Dictionary = MapLoader.load_ground_for_map(map_id)
		assert_gt(ground.size(), 100)
	if not found:
		pending("Run export_maps.py to bundle ground JSON maps")
