extends GutTest


func test_expedition_has_eight_steps() -> void:
	PlayableDemoConfig.use_expedition_demo()
	var steps := PlayableDemoConfig.steps()
	assert_eq(8, steps.size())
	PlayableDemoConfig.use_short_demo()


func test_expedition_snapshot_roundtrip() -> void:
	PlayableDemoConfig.use_expedition_demo()
	var session := GameSession.new()
	session.load_test_map()
	GameTestHelpers.new_settlement(session, Vector2i(30, 30))
	var tracker := DemoObjectiveTracker.new(session)
	tracker.current_step_index = 4
	var snap := session.to_snapshot()
	snap["demo"] = tracker.to_snapshot_demo_block()
	var session2 := GameSession.new()
	session2.load_test_map()
	assert_true(session2.try_load_snapshot(snap)["ok"])
	var tracker2 := DemoObjectiveTracker.new(session2)
	tracker2.apply_snapshot_demo_block(snap["demo"])
	assert_eq(4, tracker2.current_step_index)
	assert_eq("playable_northern_expedition", PlayableDemoConfig.snapshot_key())
	PlayableDemoConfig.use_short_demo()
