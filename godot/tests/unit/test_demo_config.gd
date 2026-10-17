extends GutTest


func test_demo_config_loads_development_map() -> void:
	assert_eq("development", DemoConfig.default_map_id())
	var session := GameSession.new()
	MapLoader.apply_map_to_session(session, DemoConfig.default_map_id())
	assert_gt(session.island.ground_map.size(), 400)


func test_demo_settlement_point() -> void:
	var p := DemoConfig.default_settlement_point()
	assert_eq(Vector2i(34, 34), p)


func test_show_start_menu_default_true() -> void:
	assert_true(DemoConfig.show_start_menu())
