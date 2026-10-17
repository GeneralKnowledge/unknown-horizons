extends GutTest


func test_health_and_field_builder_attach_from_export() -> void:
	var export := ContentLoader.load_building_export("lumberjackcamp")
	var session := GameSession.new()
	session.load_test_map()
	var building := BuildingFactory.create_building(
		session,
		GameConstants.BUILDINGS["LUMBERJACK"],
		Vector2i(20, 20),
		session.island,
		session.settlement
	)
	assert_not_null(building.health)
	assert_eq(1000, building.health.maxhealth)
	assert_not_null(building.field_builder)
	assert_eq(GameConstants.BUILDINGS["TREE"], building.field_builder.field_building_id)
