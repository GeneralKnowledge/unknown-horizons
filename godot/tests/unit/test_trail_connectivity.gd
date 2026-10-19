extends GutTest


func test_trail_requires_network_adjacency() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var island: Island = settled.island
	var settlement: Settlement = settled.settlement
	var first: Building = BuildCommand.new(
		GameConstants.BUILDINGS["TRAIL"], 30, 26, island, settlement
	).execute(session) as Building
	assert_not_null(first)
	var isolated: Variant = BuildCommand.new(
		GameConstants.BUILDINGS["TRAIL"], 36, 36, island, settlement
	).execute(session)
	assert_null(isolated)
	var connected: Building = BuildCommand.new(
		GameConstants.BUILDINGS["TRAIL"], 31, 26, island, settlement
	).execute(session) as Building
	assert_not_null(connected)
	assert_true(island.is_road(Vector2i(31, 26)))


func test_tear_trail_clears_road_tiles() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var trail: Building = BuildCommand.new(
		GameConstants.BUILDINGS["TRAIL"], 30, 26, settled.island, settled.settlement
	).execute(session) as Building
	assert_true(settled.island.is_road(Vector2i(30, 26)))
	assert_true(TearCommand.new(trail).execute(session))
	assert_false(settled.island.is_road(Vector2i(30, 26)))
