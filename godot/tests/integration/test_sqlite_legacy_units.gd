extends GutTest

const LegacyUnit = preload("res://scripts/sim/units/legacy_unit.gd")

const FIRE_SHIP_WORLDID := 1002
const FIRE_HUKER_SHIP_TYPE := 1000001


func _fire_sqlite_path() -> String:
	return (
		ProjectSettings.globalize_path("res://").path_join("..")
		.path_join("legacy/tests/game/fixtures/fire.sqlite")
		.simplify_path()
	)


func test_fire_fixture_restores_ship_as_legacy_unit() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _fire_sqlite_path()
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"])
	var report: SqliteImportReport = result["report"]
	assert_eq(1, report.ships_restored)
	assert_eq(0, report.unsupported_unit_rows)
	var session: GameSession = result["session"]
	var ship: LegacyUnit = session.get_legacy_unit(FIRE_SHIP_WORLDID)
	assert_not_null(ship)
	assert_eq("ship", ship.kind)
	assert_eq(FIRE_HUKER_SHIP_TYPE, ship.unit_type_id)
	assert_eq(Vector2i(31, 0), ship.position)
