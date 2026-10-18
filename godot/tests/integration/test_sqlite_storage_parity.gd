extends GutTest

## T1 save compatibility: building inventories after legacy SQLite load match extract.

const M7_FULL_PARITY_FIXTURES := {
	"fire": "legacy/tests/game/fixtures/fire.sqlite",
	"settlement-range": "legacy/tests/game/fixtures/settlement-range.sqlite",
	"traderoute": "legacy/tests/game/fixtures/traderoute.sqlite",
}

const M7_TOTALS_ONLY_FIXTURES := {
	"savegame-rev-76": "legacy/tests/game/fixtures/savegame-rev-76.sqlite",
}


func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


func _extract_storage_rows(sqlite_path: String, limit: int = 5000) -> Array:
	var script := _repo_root().path_join("development/godot/sqlite_extract_storage.py")
	var tmp := "user://gut_storage_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs, str(limit)], output, true)
	assert_eq(0, code, "storage extract failed: %s" % str(output))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	assert_eq(typeof(parsed), TYPE_ARRAY)
	return parsed


func _aggregate_storage(rows: Array) -> Dictionary:
	var by_wid: Dictionary = {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var wid := int(row.get("worldid", -1))
		var res_id := int(row.get("resource_id", -1))
		var amount := int(row.get("amount", 0))
		if wid < 0 or res_id < 0:
			continue
		if not by_wid.has(wid):
			by_wid[wid] = {}
		var bucket: Dictionary = by_wid[wid]
		bucket[res_id] = int(bucket.get(res_id, 0)) + amount
	return by_wid


func _nonzero_resources(bucket: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for res_key in bucket.keys():
		var amount := int(bucket[res_key])
		if amount != 0:
			out[int(res_key)] = amount
	return out


func _placed_building_worldids(session: GameSession) -> Dictionary:
	var out: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		out[int(building.worldid)] = building
	return out


func _count_applicable_storage_rows(rows: Array, placed_wids: Dictionary, settlement_rowids: Dictionary) -> int:
	var count := 0
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var wid := int(row.get("worldid", -1))
		var amount := int(row.get("amount", 0))
		if amount == 0 or int(row.get("resource_id", -1)) < 0:
			continue
		if settlement_rowids.has(wid) or placed_wids.has(wid):
			count += 1
	return count


func _legacy_settlement_rowids_from_rows(settlement_rows: Array) -> Dictionary:
	var ids: Dictionary = {}
	for row in settlement_rows:
		if typeof(row) == TYPE_DICTIONARY:
			ids[int(row.get("rowid", -1))] = true
	return ids


func _extract_settlement_rows_for_path(sqlite_path: String) -> Array:
	var script := _repo_root().path_join("development/godot/sqlite_extract_settlement.py")
	var tmp := "user://gut_settlement_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs], output, true)
	if code != 0:
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed


func _aggregate_applied_inventory_totals(
	rows: Array, placed_wids: Dictionary, settlement_rowids: Dictionary
) -> Dictionary:
	var totals: Dictionary = {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var wid := int(row.get("worldid", -1))
		var res_id := int(row.get("resource_id", -1))
		var amount := int(row.get("amount", 0))
		if res_id < 0 or amount == 0:
			continue
		if settlement_rowids.has(wid) or placed_wids.has(wid):
			totals[res_id] = int(totals.get(res_id, 0)) + amount
	return totals


func _godot_inventory_totals(session: GameSession) -> Dictionary:
	var totals: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		for res_id in _storage_on_building(building).keys():
			var amount := int(_storage_on_building(building)[res_id])
			if amount == 0:
				continue
			totals[int(res_id)] = int(totals.get(int(res_id), 0)) + amount
	for res_id in session.settlement.inventory.get_stored_resources().keys():
		var amount := session.settlement.inventory.amount(int(res_id))
		if amount == 0:
			continue
		totals[int(res_id)] = int(totals.get(int(res_id), 0)) + amount
	return totals


func _storage_on_building(building: Building) -> Dictionary:
	var inv := building.get_storage()
	if inv == null:
		return {}
	return inv.get_stored_resources()


func _assert_building_storage_matches(
	building: Building,
	expected: Dictionary,
	fixture_name: String
) -> void:
	var actual := _storage_on_building(building)
	for res_id in expected.keys():
		var exp_amt := int(expected[res_id])
		var act_amt := int(actual.get(res_id, 0))
		assert_eq(
			act_amt,
			exp_amt,
			"%s worldid %s res %s" % [fixture_name, building.worldid, res_id]
		)
	for res_id in actual.keys():
		if int(actual[res_id]) == 0:
			continue
		if not expected.has(res_id):
			fail_test(
				"%s worldid %s unexpected res %s = %s"
				% [fixture_name, building.worldid, res_id, actual[res_id]]
			)


func _assert_m7_building_storage_parity(fixture_name: String, rel_path: String) -> void:
	var path := _repo_root().path_join(rel_path)
	if not FileAccess.file_exists(path):
		pending("missing fixture %s" % rel_path)
		return
	var rows := _extract_storage_rows(path)
	var expected_by_wid := _aggregate_storage(rows)
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"], fixture_name)
	var session: GameSession = result["session"]
	var report: SqliteImportReport = result["report"]
	assert_gt(report.buildings_placed, 0, fixture_name)
	var placed := _placed_building_worldids(session)
	var settlement_ids := _legacy_settlement_rowids_from_rows(_extract_settlement_rows_for_path(path))
	var expected_compared := 0
	for wid_key in placed.keys():
		var wid: int = int(wid_key)
		if not expected_by_wid.has(wid):
			continue
		if _nonzero_resources(expected_by_wid[wid]).is_empty():
			continue
		expected_compared += 1
	var compared := 0
	for building in session.get_buildings_on_island(session.island):
		if not expected_by_wid.has(building.worldid):
			continue
		var exp: Dictionary = _nonzero_resources(expected_by_wid[building.worldid])
		if exp.is_empty():
			continue
		_assert_building_storage_matches(building, exp, fixture_name)
		compared += 1
	assert_eq(expected_compared, compared, "%s: all placed buildings with storage" % fixture_name)
	var expected_applied := _count_applicable_storage_rows(rows, placed, settlement_ids)
	assert_eq(
		report.storage_rows_applied + report.settlement_storage_rows_applied,
		expected_applied,
		"%s: storage rows applied" % fixture_name
	)


func _assert_m7_inventory_totals_at_load(fixture_name: String, rel_path: String) -> void:
	var path := _repo_root().path_join(rel_path)
	if not FileAccess.file_exists(path):
		pending("missing fixture %s" % rel_path)
		return
	var rows := _extract_storage_rows(path)
	var result := SqliteSaveLoader.load_with_report(path)
	assert_true(result["ok"], fixture_name)
	var session: GameSession = result["session"]
	var placed := _placed_building_worldids(session)
	var settlement_ids := _legacy_settlement_rowids_from_rows(_extract_settlement_rows_for_path(path))
	var expected := _aggregate_applied_inventory_totals(rows, placed, settlement_ids)
	var actual := _godot_inventory_totals(session)
	for res_id in expected.keys():
		assert_eq(
			int(expected[res_id]),
			int(actual.get(res_id, 0)),
			"%s total res %s at load (M7)" % [fixture_name, res_id]
		)
	for res_id in actual.keys():
		if int(actual[res_id]) == 0:
			continue
		assert_true(
			expected.has(res_id),
			"%s unexpected inventory res %s = %s" % [fixture_name, res_id, actual[res_id]]
		)


func test_m7_fire_building_storage_matches_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_building_storage_parity("fire", M7_FULL_PARITY_FIXTURES["fire"])
	var path := _repo_root().path_join(M7_FULL_PARITY_FIXTURES["fire"])
	var result := SqliteSaveLoader.load_with_report(path)
	var session: GameSession = result["session"]
	assert_eq(12, session.settlement.inventory.amount(GameConstants.RES["CANNON"]))
	var lumberjack := session.get_building(1019)
	assert_not_null(lumberjack)
	assert_eq(5, lumberjack.get_storage().amount(GameConstants.RES["TREES"]))


func test_m7_settlement_range_building_storage_matches_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_building_storage_parity(
		"settlement-range", M7_FULL_PARITY_FIXTURES["settlement-range"]
	)


func test_m7_traderoute_building_storage_matches_sqlite_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_building_storage_parity("traderoute", M7_FULL_PARITY_FIXTURES["traderoute"])


func test_m7_fire_inventory_totals_at_load_match_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_inventory_totals_at_load("fire", M7_FULL_PARITY_FIXTURES["fire"])


func test_m7_settlement_range_inventory_totals_at_load_match_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_inventory_totals_at_load(
		"settlement-range", M7_FULL_PARITY_FIXTURES["settlement-range"]
	)


func test_m7_traderoute_inventory_totals_at_load_match_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_inventory_totals_at_load("traderoute", M7_FULL_PARITY_FIXTURES["traderoute"])


func test_m7_savegame_rev_76_inventory_totals_at_load_match_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_m7_inventory_totals_at_load(
		"savegame-rev-76", M7_TOTALS_ONLY_FIXTURES["savegame-rev-76"]
	)


func test_fire_fixture_run_ticks_after_load() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _repo_root().path_join(M7_FULL_PARITY_FIXTURES["fire"])
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	var building_count := session.get_buildings_on_island(session.island).size()
	var tick_before := session.scheduler.cur_tick
	session.run_ticks(32)
	assert_eq(session.scheduler.cur_tick, tick_before + 32)
	assert_eq(session.get_buildings_on_island(session.island).size(), building_count)
