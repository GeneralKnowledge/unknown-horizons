extends GutTest

## Playable settlement demo: multi-step objectives, costs, snapshot demo metadata.


func test_boards_step_completes_and_advances_to_bricks() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	PlayableDemoConfig.apply_starting_resources(session.settlement)
	var tracker := DemoObjectiveTracker.new(session)
	assert_eq(0, tracker.current_step_index)
	BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 32, 32, session.island, session.settlement
	).execute(session)
	for off in [Vector2i(2, 0), Vector2i(4, 0)]:
		BuildCommand.new(
			GameConstants.BUILDINGS["TREE"], 32 + off.x, 32 + off.y, session.island, session.settlement
		).execute(session)
	session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 8)
	tracker.tick_after_sim()
	assert_eq(1, tracker.current_step_index)
	assert_false(tracker.completed)


func test_full_demo_completes_after_bricks() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var tracker := DemoObjectiveTracker.new(session)
	tracker.current_step_index = 1
	BuildCommand.new(
		GameConstants.BUILDINGS["CLAY_DEPOSIT"], 33, 33, session.island, null, true
	).execute(session)
	BuildCommand.new(
		GameConstants.BUILDINGS["CLAY_PIT"], 33, 33, session.island, session.settlement
	).execute(session)
	BuildCommand.new(
		GameConstants.BUILDINGS["BRICKYARD"], 33, 25, session.island, session.settlement
	).execute(session)
	session.settlement.inventory.alter(GameConstants.RES["BRICKS"], 4)
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


func test_step_label_short_reflects_progress() -> void:
	var session := GameSession.new()
	var tracker := DemoObjectiveTracker.new(session)
	assert_eq("step 1/2", tracker.step_label_short())
	tracker.current_step_index = 1
	assert_eq("step 2/2", tracker.step_label_short())
	tracker.completed = true
	assert_eq("demo complete", tracker.step_label_short())


func test_demo_snapshot_roundtrip_preserves_step_index() -> void:
	var session := GameSession.new()
	session.load_test_map()
	GameTestHelpers.new_settlement(session, Vector2i(30, 30))
	var tracker := DemoObjectiveTracker.new(session)
	tracker.current_step_index = 1
	var snap := session.to_snapshot()
	snap["demo"] = tracker.to_snapshot_demo_block()
	var session2 := GameSession.new()
	session2.load_test_map()
	var result := session2.try_load_snapshot(snap)
	assert_true(result["ok"])
	var tracker2 := DemoObjectiveTracker.new(session2)
	tracker2.apply_snapshot_demo_block(snap["demo"])
	assert_eq(1, tracker2.current_step_index)


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
