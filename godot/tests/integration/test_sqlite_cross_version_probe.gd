extends GutTest


func test_fire_probe_matches_godot_import_counts() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var sqlite_path := repo.path_join("legacy/tests/game/fixtures/fire.sqlite")
	if not FileAccess.file_exists(sqlite_path):
		pending("missing fixture")
		return
	var script := repo.path_join("development/godot/sqlite_cross_version_probe.py")
	var tmp := "user://cross_version_probe.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs], output, true)
	assert_eq(0, code, str(output))
	var probe: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	assert_eq(typeof(probe), TYPE_DICTIONARY)

	var result := SqliteSaveLoader.load_with_report(sqlite_path)
	assert_true(result["ok"])
	var report: SqliteImportReport = result["report"]
	assert_eq(int(probe["buildings_extracted"]), report.buildings_extracted)
	assert_eq(int(probe["collector_rows"]), report.collector_rows_in_save)
	assert_eq(int(probe["ship_rows"]), report.ships_restored)
