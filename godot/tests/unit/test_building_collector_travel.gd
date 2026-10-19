extends GutTest


func test_collector_start_travel_records_path_and_ticks() -> void:
	var land: Dictionary = {}
	for x in range(20, 30):
		for y in range(20, 30):
			land[Vector2i(x, y)] = SimGround.Kind.LAND
	var gts := GameTestSession.start(true)
	gts.session.island.load_ground(land)
	var home: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 22, 22)
	assert_eq(1, home.collecting.collectors.size())
	var bc: BuildingCollector = home.collecting.collectors[0]
	var ticks := bc._start_travel(Vector2i(22, 22), Vector2i(28, 22))
	assert_true(ticks > 0)
	assert_true(bc.view_path.size() >= 2)
	assert_eq(Vector2i(28, 22), bc.view_path[bc.view_path.size() - 1])
	var home_ticks := bc._start_travel(Vector2i(28, 22), Vector2i(22, 22))
	assert_true(home_ticks > 0)
	assert_eq(Vector2i(22, 22), bc.view_path[bc.view_path.size() - 1])
