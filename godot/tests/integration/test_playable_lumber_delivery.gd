extends GutTest

## Playable settlement demo: objective driven by real sim state + snapshot demo metadata.


func test_objective_completes_when_warehouse_has_boards() -> void:
	var session := GameSession.new()
	session.load_test_map()
	GameTestHelpers.new_settlement(session, Vector2i(30, 30))
	var tracker := DemoObjectiveTracker.new(session)
	tracker.target_boards = 5
	tracker.min_trees = 2
	assert_false(tracker.completed)
	BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 32, 32, session.island, session.settlement
	).execute(session)
	for off in [Vector2i(2, 0), Vector2i(4, 0)]:
		BuildCommand.new(
			GameConstants.BUILDINGS["TREE"], 32 + off.x, 32 + off.y, session.island, session.settlement
		).execute(session)
	session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 5)
	tracker.tick_after_sim()
	assert_true(tracker.completed)


func test_invalid_placement_leaves_building_count_unchanged() -> void:
	var gts := GameTestSession.start(true)
	var before := gts.session.get_buildings_on_island(gts.session.island).size()
	var tool := BuildTool.new(gts.session)
	tool.building_id = GameConstants.BUILDINGS["LUMBERJACK"]
	var reason := tool.placement_failure_reason(Vector2i(0, 0))
	assert_false(reason.is_empty())
	var placed := tool.try_place(Vector2i(0, 0))
	assert_null(placed)
	var after := gts.session.get_buildings_on_island(gts.session.island).size()
	assert_eq(before, after)


func test_demo_snapshot_roundtrip_preserves_completion() -> void:
	var session := GameSession.new()
	session.load_test_map()
	GameTestHelpers.new_settlement(session, Vector2i(30, 30))
	var tracker := DemoObjectiveTracker.new(session)
	tracker.completed = true
	var snap := session.to_snapshot()
	snap["demo"] = tracker.to_snapshot_demo_block()
	var session2 := GameSession.new()
	session2.load_test_map()
	var result := session2.try_load_snapshot(snap)
	assert_true(result["ok"])
	var tracker2 := DemoObjectiveTracker.new(session2)
	tracker2.apply_snapshot_demo_block(snap["demo"])
	assert_true(tracker2.completed)


func test_lumberjack_production_increases_boards_with_trees() -> void:
	var gts := GameTestSession.start(true)
	var jack: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(jack)
	for x_off in [2, 4]:
		for y_off in [0, 2]:
			var tree: Building = gts.build(
				GameConstants.BUILDINGS["TREE"], 30 + x_off, 30 + y_off
			)
			assert_not_null(tree)
			tree.get_producer().finish_production_now()
	gts.run_seconds(30)
	var boards := jack.get_storage().amount(GameConstants.RES["BOARDS"])
	assert_true(boards > 0)
