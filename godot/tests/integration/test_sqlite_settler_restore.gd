extends GutTest

const FIRE_RESIDENTIAL_WORLDID := 1196


func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


func _settler_rows_from_extract(sqlite_path: String) -> Array:
	var script := _repo_root().path_join("development/godot/sqlite_extract_settler.py")
	var tmp := "user://gut_settler_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs], output, true)
	assert_eq(0, code)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	assert_eq(typeof(parsed), TYPE_ARRAY)
	return parsed


func test_fire_fixture_restores_settler_meta_on_residential() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _repo_root().path_join("legacy/tests/game/fixtures/fire.sqlite")
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"])
	var report: SqliteImportReport = result["report"]
	assert_gt(report.settler_building_rows_applied, 0)
	var session: GameSession = result["session"]
	var home := session.get_building(FIRE_RESIDENTIAL_WORLDID)
	assert_not_null(home)
	assert_eq(GameConstants.BUILDINGS["RESIDENTIAL"], home.building_id)
	assert_not_null(home.settler)
	assert_eq(1, home.settler.inhabitants)
	assert_eq(1, int(home.get_meta("legacy_inhabitants")))
	assert_eq(0, home.settler.level)
	assert_eq(3, home.settler.inhabitants_max())
	var happiness_id := int(GameConstants.RES["HAPPINESS"])
	assert_eq(50, home.get_storage().amount(happiness_id))
	assert_eq(50, home.settler.get_happiness())


func test_fire_fixture_settler_inhabitant_total_matches_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _repo_root().path_join("legacy/tests/game/fixtures/fire.sqlite")
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var rows := _settler_rows_from_extract(path)
	var expected := 0
	for row in rows:
		if typeof(row) == TYPE_DICTIONARY:
			expected += int(row.get("inhabitants", 0))
	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	assert_eq(expected, LegacySettlerComponent.total_inhabitants(session))


func test_fire_fixture_settler_inhabitants_stable_after_ticks() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _repo_root().path_join("legacy/tests/game/fixtures/fire.sqlite")
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var session := SqliteSaveLoader.load(path)
	var before := LegacySettlerComponent.total_inhabitants(session)
	session.run_ticks(128)
	assert_eq(before, LegacySettlerComponent.total_inhabitants(session))
