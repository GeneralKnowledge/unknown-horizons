extends GutTest


func test_second_build_on_same_tile_does_not_register() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var island: Island = settled.island
	var settlement: Settlement = settled.settlement
	var first: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session) as Building
	assert_not_null(first)
	var count_after_first := session.get_buildings_on_island(island).size()
	var second: Variant = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session)
	assert_null(second)
	assert_eq(count_after_first, session.get_buildings_on_island(island).size())
