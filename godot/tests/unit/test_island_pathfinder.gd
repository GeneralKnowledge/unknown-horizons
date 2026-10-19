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


func test_water_blocks_path() -> void:
	var land: Dictionary = {}
	for x in range(5, 15):
		for y in range(5, 15):
			if x == 10:
				continue
			land[Vector2i(x, y)] = SimGround.Kind.LAND
	var island := Island.new(1, null)
	island.load_ground(land)
	var path := IslandPathfinder.find_path(island, Vector2i(6, 6), Vector2i(14, 6))
	assert_true(path.is_empty())


func test_unreachable_within_max_steps() -> void:
	var land: Dictionary = {}
	for x in range(0, 4):
		land[Vector2i(x, 0)] = SimGround.Kind.LAND
	var island := Island.new(1, null)
	island.load_ground(land)
	var path := IslandPathfinder.find_path(island, Vector2i(0, 0), Vector2i(3, 0), 1)
	assert_true(path.is_empty())


func test_road_tile_walkable_on_coast() -> void:
	var land: Dictionary = {}
	land[Vector2i(8, 8)] = SimGround.Kind.SHALLOW_WATER
	var island := Island.new(1, null)
	island.load_ground(land)
	island.set_road_tile(Vector2i(8, 8))
	var path := IslandPathfinder.find_path(island, Vector2i(8, 8), Vector2i(8, 8))
	assert_eq(1, path.size())
