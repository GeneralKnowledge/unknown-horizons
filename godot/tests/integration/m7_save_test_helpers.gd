class_name M7SaveTestHelpers
extends RefCounted

## Shared helpers for M7 legacy save parity GUT.


static func repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func extract_storage_rows(sqlite_path: String, limit: int = 10000) -> Array:
	var script := repo_root().path_join("development/godot/sqlite_extract_storage.py")
	var tmp := "user://m7_storage_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs, str(limit)], output, true)
	if code != 0:
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed


static func extract_production_rows(sqlite_path: String, limit: int = 10000) -> Array:
	var script := repo_root().path_join("development/godot/sqlite_extract_production.py")
	var tmp := "user://m7_production_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute(
		"python3", [script, sqlite_path, tmp_abs, str(limit)], output, true
	)
	if code != 0:
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed


static func extract_session_dict(sqlite_path: String) -> Dictionary:
	var script := repo_root().path_join("development/godot/sqlite_extract_session.py")
	var tmp := "user://m7_session_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs], output, true)
	if code != 0:
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func extract_settlement_rowids(sqlite_path: String) -> Dictionary:
	var script := repo_root().path_join("development/godot/sqlite_extract_settlement.py")
	var tmp := "user://m7_settlement_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute("python3", [script, sqlite_path, tmp_abs], output, true)
	if code != 0:
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(parsed) != TYPE_ARRAY:
		return {}
	var ids: Dictionary = {}
	for row in parsed:
		if typeof(row) == TYPE_DICTIONARY:
			ids[int(row.get("rowid", -1))] = true
	return ids


static func placed_building_worldids(session: GameSession) -> Dictionary:
	var out: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		out[int(building.worldid)] = building
	return out


static func aggregate_applied_inventory_totals(
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


static func godot_inventory_totals(session: GameSession) -> Dictionary:
	var totals: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		var inv: Inventory = building.get_storage()
		if inv == null:
			continue
		for res_id in inv.get_stored_resources().keys():
			var amount := int(inv.amount(int(res_id)))
			if amount == 0:
				continue
			totals[int(res_id)] = int(totals.get(int(res_id), 0)) + amount
	for res_id in session.settlement.inventory.get_stored_resources().keys():
		var amount := session.settlement.inventory.amount(int(res_id))
		if amount == 0:
			continue
		totals[int(res_id)] = int(totals.get(int(res_id), 0)) + amount
	return totals


static func assert_inventory_totals_at_load(gut: GutTest, fixture_name: String, rel_path: String) -> void:
	var path := repo_root().path_join(rel_path)
	if not FileAccess.file_exists(path):
		gut.pending("missing fixture %s" % rel_path)
		return
	var rows := extract_storage_rows(path)
	var result := SqliteSaveLoader.load_with_report(path)
	gut.assert_true(result["ok"], fixture_name)
	var session: GameSession = result["session"]
	var placed := placed_building_worldids(session)
	var settlement_ids := extract_settlement_rowids(path)
	var expected := aggregate_applied_inventory_totals(rows, placed, settlement_ids)
	var actual := godot_inventory_totals(session)
	for res_id in expected.keys():
		gut.assert_eq(
			int(expected[res_id]),
			int(actual.get(res_id, 0)),
			"%s total res %s at load" % [fixture_name, res_id]
		)
