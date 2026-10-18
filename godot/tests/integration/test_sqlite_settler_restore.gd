extends GutTest

const FIRE_RESIDENTIAL_WORLDID := 1196


func test_fire_fixture_restores_settler_meta_on_residential() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := (
		ProjectSettings.globalize_path("res://").path_join("..")
		.path_join("legacy/tests/game/fixtures/fire.sqlite")
		.simplify_path()
	)
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
	assert_eq(1, int(home.get_meta("legacy_inhabitants")))
