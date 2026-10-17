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


func test_settlement_inventory_round_trip() -> void:
	var gts := GameTestSession.start(true)
	gts.session.settlement.inventory.reset_all()
	gts.session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 12)
	gts.session.settlement.inventory.alter(GameConstants.RES["GOLD"], 100)
	var snap := gts.session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	assert_eq(12, session2.settlement.inventory.amount(GameConstants.RES["BOARDS"]))
	assert_eq(100, session2.settlement.inventory.amount(GameConstants.RES["GOLD"]))


func test_boards_in_settlement_after_load() -> void:
	var gts := GameTestSession.start(true)
	gts.session.settlement.inventory.reset_all()
	gts.session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 7)
	var snap := gts.session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	assert_eq(7, session2.settlement.inventory.amount(GameConstants.RES["BOARDS"]))


func test_load_producing_lumberjack_mid_production() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	lj.get_producer().set_all_active(false)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], 9)
	var wid := lj.worldid
	var snap := gts.session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	var loaded: Building = session2.get_building(wid)
	assert_not_null(loaded)
	assert_false(loaded.get_producer().is_active())
	assert_eq(9, loaded.get_storage().amount(GameConstants.RES["BOARDS"]))
	loaded.get_producer().toggle_active()
	assert_true(loaded.get_producer().is_active())


func test_multiple_buildings_snapshot_order() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], 5)
	var snap := gts.session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	var found: Building = null
	for b in session2.get_buildings_on_island(session2.island):
		if b.building_id == GameConstants.BUILDINGS["LUMBERJACK"]:
			found = b
			break
	assert_not_null(found)
	assert_eq(5, found.get_storage().amount(GameConstants.RES["BOARDS"]))
