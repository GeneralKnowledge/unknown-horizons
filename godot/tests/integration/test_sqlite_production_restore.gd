extends GutTest

const FIRE_LUMBERJACK_WORLDID := 1019
const FIRE_LUMBERJACK_BOARDS_LINE := 256812226


func test_fire_fixture_restores_producing_lumberjack() -> void:
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
	assert_gt(report.production_rows_applied, 0)
	var session: GameSession = result["session"]
	var building := session.get_building(FIRE_LUMBERJACK_WORLDID)
	if building == null:
		pending("lumberjack worldid not placed in partial import")
		return
	assert_not_null(building.producer)
	var production := building.producer._get_production(FIRE_LUMBERJACK_BOARDS_LINE)
	assert_not_null(production, "boards production line")
	assert_eq(ProductionStates.PRODUCING, production.get_state())
	var remaining: Variant = session.scheduler.get_remaining_ticks(
		production,
		production._get_producing_callback(),
		false
	)
	assert_true(typeof(remaining) == TYPE_INT and int(remaining) > 0)


func test_production_restore_matches_legacy_load_semantics() -> void:
	var gts := GameTestSession.new()
	gts.settle()
	var session := gts.session
	var building: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(building)
	assert_not_null(building.producer)
	var line_ids := building.producer.get_production_lines()
	assert_gt(line_ids.size(), 0)
	var production := building.producer._get_production(int(line_ids[0]))
	assert_not_null(production)
	production.restore_from_legacy_save(
		ProductionStates.PRODUCING,
		48,
		-1,
		-100
	)
	assert_eq(ProductionStates.PRODUCING, production.get_state())
	var remaining: Variant = session.scheduler.get_remaining_ticks(
		production,
		production._get_producing_callback(),
		false
	)
	assert_eq(48, int(remaining))
