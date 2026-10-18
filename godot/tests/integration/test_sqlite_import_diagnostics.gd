extends GutTest


func test_fire_fixture_reports_partial_import_with_diagnostics() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := ProjectSettings.globalize_path("res://").path_join("../legacy/tests/game/fixtures/fire.sqlite").simplify_path()
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"])
	var report: SqliteImportReport = result["report"]
	assert_not_null(report)
	assert_gt(report.buildings_extracted, 0)
	assert_gt(report.buildings_placed, 0)
	assert_eq(report.buildings_placed, report.buildings_extracted)
	assert_eq(0, int(report.rejection_counts.get("placement_failed", 0)))
	assert_eq(0, report.collectors_skipped_yaml_duplicate)
	assert_eq(0, report.unsupported_unit_rows)
	assert_eq(1, report.ships_restored)
	assert_gt(report.collector_jobs_applied, 0)
	assert_gt(report.settler_building_rows_applied, 0)
	assert_true(report.partial, "partial until unsupported units and storage gaps are gone")
	assert_true(report.rejection_counts.size() >= 0)
	var session: GameSession = result["session"]
	var attached := SqliteSaveLoader.get_report(session)
	assert_not_null(attached)
	assert_eq(report.buildings_placed, attached.buildings_placed)


func test_truncation_marker_when_limit_applied() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var script := repo.path_join("development/godot/sqlite_extract_buildings.py")
	var sqlite := repo.path_join("legacy/tests/game/fixtures/fire.sqlite")
	var tmp := "user://diag_extract_test.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute(
		"python3",
		[script, sqlite, tmp_abs, "2", "--include-skipped"],
		output,
		true
	)
	assert_eq(0, code)
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	var truncated := false
	for row in rows:
		if typeof(row) == TYPE_DICTIONARY and row.get("_skipped", false):
			truncated = true
	assert_true(truncated)
