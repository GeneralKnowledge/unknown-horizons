extends GutTest


func test_fire_extract_bundle_matches_sqlite_load() -> void:
	var bundle_path := "res://resources/fixtures/sqlite_bundles/fire.extract.json"
	if not FileAccess.file_exists(bundle_path):
		pending("missing bundled extract — run sqlite_extract_bundle.py")
		return
	var bundle_abs := ProjectSettings.globalize_path(bundle_path)
	var sqlite_path := (
		ProjectSettings.globalize_path("res://").path_join("..")
		.path_join("legacy/tests/game/fixtures/fire.sqlite")
		.simplify_path()
	)
	if not FileAccess.file_exists(sqlite_path):
		pending("missing sqlite fixture")
		return

	var from_sqlite := SqliteSaveLoader.load_with_report(sqlite_path)
	var from_bundle := SqliteSaveLoader.load_with_report(bundle_abs)
	assert_true(from_sqlite["ok"])
	assert_true(from_bundle["ok"])
	var rs: SqliteImportReport = from_sqlite["report"]
	var rb: SqliteImportReport = from_bundle["report"]
	assert_eq(rs.buildings_placed, rb.buildings_placed)
	assert_eq(rs.collectors_restored, rb.collectors_restored)
	assert_eq(rs.ships_restored, rb.ships_restored)
	assert_eq(rs.legacy_settlement_worldid, rb.legacy_settlement_worldid)
