extends GutTest


func test_expedition_has_eight_steps() -> void:
	PlayableDemoConfig.use_expedition_demo()
	var steps := PlayableDemoConfig.steps()
	assert_eq(8, steps.size())
	PlayableDemoConfig.use_short_demo()


func test_expedition_brickyard_chain_on_development() -> void:
	PlayableDemoConfig.use_expedition_demo()
	var at := PlayableDemoConfig.clay_deposit_point()
	assert_eq(Vector2i(33, 33), at)
	var gts := GameTestSession.new()
	gts.session = GameSession.new()
	MapLoader.apply_map_to_session(gts.session, PlayableDemoConfig.map_id())
	GameTestHelpers.new_settlement(gts.session, PlayableDemoConfig.settlement_point())
	PlayableDemoConfig.apply_starting_resources(gts.session.settlement)
	gts.session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 40)
	gts.session.settlement.inventory.alter(GameConstants.RES["GOLD"], 5000)
	gts.player = SimPlayer.new(gts.session.allocate_worldid(), gts.session.settlement)
	var deposit: Building = gts.build_ownerless(GameConstants.BUILDINGS["CLAY_DEPOSIT"], at.x, at.y)
	assert_not_null(deposit)
	var cfg := PlayableDemoConfig.clay_deposit_cfg()
	deposit.get_storage().alter(GameConstants.RES["RAW_CLAY"], int(cfg.get("seed_raw_clay", 10)))
	var pit: Building = gts.build(GameConstants.BUILDINGS["CLAY_PIT"], at.x, at.y)
	assert_not_null(pit)
	var brickyard: Building = gts.build(GameConstants.BUILDINGS["BRICKYARD"], 33, 25)
	assert_not_null(brickyard)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 28, 32)
	assert_not_null(lj)
	var smokery: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_SMOKERY"], 40, 28)
	assert_not_null(smokery)
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
