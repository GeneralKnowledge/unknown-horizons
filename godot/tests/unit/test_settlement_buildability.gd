extends GutTest


func test_warehouse_radius_allows_nearby_lumberjack() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var export := ContentLoader.load_building_export("lumberjackcamp")
	var origin := Vector2i(30, 30)
	var size := Vector2i(int(export.get("size_x", 1)), int(export.get("size_y", 1)))
	assert_true(settlement.can_place_building(origin, size))
