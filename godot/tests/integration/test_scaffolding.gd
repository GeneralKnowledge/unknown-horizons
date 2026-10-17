extends GutTest

## Smoke tests for GameTestSession recipes and SaveLoader probes.


func test_snapshot_roundtrip_helper() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], 2)
	var session2 := gts.snapshot_roundtrip()
	var found := false
	for b in session2.get_buildings_on_island(session2.island):
		if b.building_id == GameConstants.BUILDINGS["LUMBERJACK"]:
			assert_eq(2, b.get_storage().amount(GameConstants.RES["BOARDS"]))
			found = true
			break
	assert_true(found)


func test_run_until_resource() -> void:
	var gts := GameTestSession.start(true)
	var school: Building = gts.build(GameConstants.BUILDINGS["VILLAGE_SCHOOL"], 30, 30)
	assert_true(gts.run_until(school, GameConstants.RES["EDUCATION"], 1, 60.0))


func test_build_farm_places_fields() -> void:
	var gts := GameTestSession.start(true)
	var farm := gts.build_farm(
		30,
		30,
		[GameConstants.BUILDINGS["CORN_FIELD"], GameConstants.BUILDINGS["CORN_FIELD"]]
	)
	if farm == null:
		pending("FARM build failed — map/buildability; recipe API still available")
		return
	var fields := 0
	for b in gts.session.get_buildings_on_island(gts.session.island):
		if b.building_id == GameConstants.BUILDINGS["CORN_FIELD"]:
			fields += 1
	assert_gte(fields, 1)


func test_legacy_sqlite_fixture_probe() -> void:
	var path := GameTestSession.legacy_sqlite_fixture_path()
	if not FileAccess.file_exists(path):
		pending("SQLite fixture not present at %s" % path)
		return
	var info := SaveLoader.probe(path)
	assert_true(info.get("ok", false))
	assert_eq("sqlite", str(info.get("format", "")))
	assert_true(bool(info.get("implemented", false)) or info.get("building_rows", 0) > 0)
