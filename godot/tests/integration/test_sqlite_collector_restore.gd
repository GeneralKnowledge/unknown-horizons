extends GutTest

const FIRE_WAREHOUSE_WORLDID := 1011
const FIRE_LUMBERJACK_WORLDID := 1019
const FIRE_STORAGE_COLLECTOR_TYPE := 1000008
const FIRE_LUMBERJACK_COLLECTOR_TYPE := 1000010
const FIRE_COLLECTOR_COUNT := 16
const FIRE_SETTLEMENT_WORLDID := 1012
const FIRE_ISLAND_WORLDID := 1001


func test_fire_fixture_restores_collectors_from_save() -> void:
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
	assert_eq(FIRE_COLLECTOR_COUNT, report.collector_rows_in_save)
	assert_eq(FIRE_COLLECTOR_COUNT, report.collectors_restored)
	assert_gt(report.collectors_save_homes, 0)

	var session: GameSession = result["session"]
	var collector_total := 0
	for b in session.get_buildings_on_island(session.island):
		if b.collecting != null:
			collector_total += b.collecting.collectors.size()
	assert_eq(report.collectors_restored, collector_total)

	var warehouse := session.get_building(FIRE_WAREHOUSE_WORLDID)
	if warehouse != null:
		assert_not_null(warehouse.collecting)
		assert_eq(3, warehouse.collecting.collectors.size())

	var lumberjack := session.get_building(FIRE_LUMBERJACK_WORLDID)
	assert_not_null(lumberjack, "lumberjack worldid should be placed in fire fixture")
	assert_eq(GameConstants.BUILDINGS["LUMBERJACK"], lumberjack.building_id)
	assert_not_null(lumberjack.collecting)
	assert_eq(1, lumberjack.collecting.collectors.size())

	session.run_ticks(64)
	assert_gte(session.scheduler.cur_tick, 0)


func test_fire_fixture_restores_legacy_settlement_and_island_worldids() -> void:
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
	assert_eq(FIRE_SETTLEMENT_WORLDID, report.legacy_settlement_worldid)
	assert_eq(FIRE_ISLAND_WORLDID, report.legacy_island_worldid)
	var session: GameSession = result["session"]
	assert_eq(FIRE_SETTLEMENT_WORLDID, session.settlement.worldid)
	assert_eq(FIRE_ISLAND_WORLDID, session.island.worldid)
	assert_same(session.settlement, session.registry.get_by_id(FIRE_SETTLEMENT_WORLDID))


func test_fire_fixture_settlement_inventory_from_storage() -> void:
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
	assert_gt(report.settlement_storage_rows_applied, 0)
	var session: GameSession = result["session"]
	assert_eq(12, session.settlement.inventory.amount(GameConstants.RES["CANNON"]))
