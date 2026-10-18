extends GutTest

const M7_PRODUCTION_FIXTURES := {
	"fire": "legacy/tests/game/fixtures/fire.sqlite",
	"settlement-range": "legacy/tests/game/fixtures/settlement-range.sqlite",
}


func _assert_production_parity(fixture_name: String, rel_path: String) -> void:
	var path := M7SaveTestHelpers.repo_root().path_join(rel_path)
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var rows := M7SaveTestHelpers.extract_production_rows(path)
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"], fixture_name)
	var session: GameSession = result["session"]
	var compared := 0
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var owner_wid := int(row.get("owner_worldid", -1))
		var line_id := int(row.get("prod_line_id", -1))
		var building := session.get_building(owner_wid)
		if building == null or building.producer == null:
			continue
		var production := building.producer._get_production(line_id)
		if production == null:
			fail_test(
				"%s missing production line %s on worldid %s"
				% [fixture_name, line_id, owner_wid]
			)
			return
		var exp_state := int(row.get("state", ProductionStates.NONE))
		assert_eq(
			exp_state,
			production.get_state(),
			"%s worldid %s line %s state" % [fixture_name, owner_wid, line_id]
		)
		if exp_state == ProductionStates.PRODUCING:
			var remaining: Variant = session.scheduler.get_remaining_ticks(
				production,
				production._get_producing_callback(),
				false
			)
			assert_eq(
				int(row.get("remaining_ticks", 0)),
				int(remaining),
				"%s worldid %s line %s remaining_ticks"
				% [fixture_name, owner_wid, line_id]
			)
		compared += 1
	assert_gt(compared, 0, "%s: expected production rows on placed buildings" % fixture_name)


func test_m7_fire_production_rows_match_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_production_parity("fire", M7_PRODUCTION_FIXTURES["fire"])


func test_m7_settlement_range_production_rows_match_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_production_parity(
		"settlement-range", M7_PRODUCTION_FIXTURES["settlement-range"]
	)
