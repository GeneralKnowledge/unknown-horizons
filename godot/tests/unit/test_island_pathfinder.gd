extends GutTest


func test_path_on_open_land() -> void:
	var land: Dictionary = {}
	for x in range(5, 15):
		for y in range(5, 15):
			land[Vector2i(x, y)] = SimGround.Kind.LAND
	var island := Island.new(1, null)
	island.load_ground(land)
	var path := IslandPathfinder.find_path(island, Vector2i(6, 6), Vector2i(10, 6))
	assert_true(path.size() >= 5)
