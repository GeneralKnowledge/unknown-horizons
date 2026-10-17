extends GutTest


func test_json_snapshot_loader_file_roundtrip() -> void:
	var gts := GameTestSession.start(true)
	gts.session.settlement.inventory.reset_all()
	gts.session.settlement.inventory.alter(GameConstants.RES["GOLD"], 42)
	var snap := gts.session.to_snapshot()
	var path := OS.get_cache_dir().path_join("uh_godot_test_snapshot.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(snap))
	f.close()
	var loaded := JsonSnapshotLoader.load_from_file(path)
	assert_eq(42, loaded.settlement.inventory.amount(GameConstants.RES["GOLD"]))


func test_toggle_active_command_after_load() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	lj.get_producer().set_all_active(false)
	var snap := gts.session.to_snapshot()
	var session2 := JsonSnapshotLoader.load_from_dict(snap)
	var loaded: Building = null
	for b in session2.get_buildings_on_island(session2.island):
		if b.building_id == GameConstants.BUILDINGS["LUMBERJACK"]:
			loaded = b
			break
	assert_not_null(loaded)
	assert_false(loaded.get_producer().is_active())
	session2.manager.execute(ToggleActiveCommand.new(loaded))
	assert_true(loaded.get_producer().is_active())
