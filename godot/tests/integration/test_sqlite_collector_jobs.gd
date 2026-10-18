extends GutTest


func test_fire_fixture_applies_active_collector_jobs_at_load() -> void:
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
	assert_gt(report.collector_job_rows_in_save, 0)
	assert_gt(report.collector_jobs_applied, 0)
	assert_gt(report.collector_job_history_rows_in_save, 0)
	assert_true(report.partial)
	var session: GameSession = result["session"]
	var cargo_found := false
	for building in session.get_buildings_on_island(session.island):
		if building.collecting == null:
			continue
		for collector in building.collecting.collectors:
			if collector is BuildingCollector and collector.has_meta("legacy_job_cargo"):
				var cargo: Dictionary = collector.get_meta("legacy_job_cargo")
				if not cargo.is_empty():
					cargo_found = true
					break
		if cargo_found:
			break
	assert_true(cargo_found, "expected in-flight cargo on at least one collector")


func test_fire_fixture_deposits_legacy_collector_cargo_after_ticks() -> void:
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
	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	var cargo_before := _legacy_cargo_total(session)
	assert_gt(cargo_before, 0)
	var warehouse := session.get_building(1011)
	assert_not_null(warehouse)
	var boards_id := int(GameConstants.RES["BOARDS"])
	# Storage collectors on the warehouse deliver into settlement inventory.
	var boards_before := session.settlement.inventory.amount(boards_id)
	session.run_ticks(96)
	assert_eq(0, _legacy_cargo_total(session), "legacy in-flight cargo should be delivered")
	assert_gt(session.settlement.inventory.amount(boards_id), boards_before)


static func _legacy_cargo_total(session: GameSession) -> int:
	var total := 0
	for building in session.get_buildings_on_island(session.island):
		if building.collecting == null:
			continue
		for collector in building.collecting.collectors:
			if collector is BuildingCollector:
				total += collector.legacy_job_cargo_amount()
	return total
