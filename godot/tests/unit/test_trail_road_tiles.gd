extends GutTest


func test_trail_placement_marks_road_tiles() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var island: Island = settled.island
	var settlement: Settlement = settled.settlement
	var trail: Building = BuildCommand.new(
		GameConstants.BUILDINGS["TRAIL"], 30, 31, island, settlement
	).execute(session) as Building
	assert_not_null(trail)
	assert_true(island.is_road(Vector2i(30, 31)))
