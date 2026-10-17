extends GutTest


func test_load_inactive_production() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island

	var lj: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session) as Building
	lj.get_producer().set_all_active(false)
	var wid: int = lj.worldid
	session.run_seconds(1)

	var snap := session.to_snapshot()
	assert_eq(GameSession.SNAPSHOT_VERSION, int(snap.get("schema_version", 0)))
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)

	var loaded: Building = session2.registry.get_by_id(wid)
	assert_not_null(loaded)
	assert_false(loaded.get_producer().is_active())
	loaded.get_producer().toggle_active()
	assert_true(loaded.get_producer().is_active())


func test_load_producing_lumberjack() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	lj.get_producer().set_all_active(false)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], 3)
	var wid: int = lj.worldid
	var snap := gts.session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	var loaded: Building = session2.registry.get_by_id(wid)
	assert_not_null(loaded)
	assert_false(loaded.get_producer().is_active())
	assert_eq(3, loaded.get_storage().amount(GameConstants.RES["BOARDS"]))
