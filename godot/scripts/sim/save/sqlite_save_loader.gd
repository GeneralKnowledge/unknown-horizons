class_name SqliteSaveLoader
extends RefCounted

## Legacy UH savegames (.sqlite). Partial import with diagnostics (desktop).

const MAGIC := "SQLite format 3"
const META_REPORT := "sqlite_import_report"
const EXTRACT_BUILDINGS_SCRIPT := "development/godot/sqlite_extract_buildings.py"
const EXTRACT_STORAGE_SCRIPT := "development/godot/sqlite_extract_storage.py"
const EXTRACT_METADATA_SCRIPT := "development/godot/sqlite_extract_metadata.py"
const EXTRACT_SESSION_SCRIPT := "development/godot/sqlite_extract_session.py"
const EXTRACT_UNITS_SCRIPT := "development/godot/sqlite_extract_units.py"
const EXTRACT_PRODUCTION_SCRIPT := "development/godot/sqlite_extract_production.py"
const EXTRACT_SETTLEMENT_SCRIPT := "development/godot/sqlite_extract_settlement.py"
const PREPARE_SAVE_SCRIPT := "development/godot/sqlite_prepare_save.py"
const DEFAULT_BUILDING_LIMIT := 0


static func is_sqlite_file(path: String) -> bool:
	if path.ends_with(".sqlite.bz2") and FileAccess.file_exists(path):
		return true
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var header := f.get_buffer(16).get_string_from_ascii()
	f.close()
	return header.begins_with(MAGIC)


static func get_report(session: GameSession) -> SqliteImportReport:
	if session == null or not session.has_meta(META_REPORT):
		return null
	return SqliteImportReport.from_dictionary(session.get_meta(META_REPORT))


static func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func _prepare_sqlite_path(path: String) -> String:
	var tmp_dir := ProjectSettings.globalize_path("user://sqlite_prepare")
	var script := _repo_root().path_join(PREPARE_SAVE_SCRIPT)
	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[script, path, tmp_dir],
		output,
		true
	)
	if exit_code != 0:
		push_error("sqlite_prepare_save failed: %s" % str(output))
		return ""
	for line in output:
		var p := str(line).strip_edges()
		if p.ends_with(".sqlite") and FileAccess.file_exists(p):
			return p
	return ""


static func _run_python_extract(script_rel: String, sqlite_path: String, tmp_user: String, extra: Array = []) -> String:
	var script := _repo_root().path_join(script_rel)
	var output: Array = []
	var args: Array = [script, sqlite_path, ProjectSettings.globalize_path(tmp_user)]
	args.append_array(extra)
	var exit_code := OS.execute("python3", args, output, true)
	if exit_code != 0:
		push_warning("%s failed: %s" % [script_rel, str(output)])
		return ""
	if not FileAccess.file_exists(tmp_user):
		return ""
	return FileAccess.get_file_as_string(tmp_user)


static func _extract_buildings_json(sqlite_path: String, limit: int = DEFAULT_BUILDING_LIMIT) -> String:
	if OS.has_feature("web"):
		push_error("SQLite save import is not supported in browser builds; use JSON snapshots.")
		return ""
	return _run_python_extract(
		EXTRACT_BUILDINGS_SCRIPT,
		sqlite_path,
		"user://sqlite_buildings_extract.json",
		[str(limit), "--include-skipped"],
	)


static func probe(path: String) -> Dictionary:
	if not is_sqlite_file(path):
		return {"ok": false, "error": "not_sqlite", "path": path}
	var result := load_with_report(path)
	if not result["ok"]:
		return {"ok": false, "error": result.get("error", "load_failed"), "path": path}
	var report: SqliteImportReport = result["report"]
	return {
		"ok": true,
		"path": path,
		"partial": report.partial,
		"building_rows": report.buildings_extracted,
		"buildings_placed": report.buildings_placed,
		"report": report.to_dictionary(),
	}


static func load(path: String) -> GameSession:
	var result := load_with_report(path)
	if not result["ok"]:
		return null
	return result["session"]


static func load_with_report(path: String) -> Dictionary:
	var report := SqliteImportReport.new()
	report.source_path = path
	if OS.has_feature("web"):
		return {"ok": false, "error": "web_unsupported", "session": null, "report": report}
	if not is_sqlite_file(path):
		return {"ok": false, "error": "not_sqlite", "session": null, "report": report}

	var sqlite_path := _prepare_sqlite_path(path)
	if sqlite_path.is_empty():
		sqlite_path = path

	var meta := _extract_metadata_json(sqlite_path)
	report.savegamerev = int(meta.get("savegamerev", "-1"))
	var map_name := str(meta.get("map_name", ""))
	report.map_id = MapLoader.legacy_map_name_to_id(map_name)

	var json_text := _extract_buildings_json(sqlite_path)
	if json_text.is_empty():
		return {"ok": false, "error": "extract_failed", "session": null, "report": report}
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return {"ok": false, "error": "extract_invalid_json", "session": null, "report": report}

	var session := GameSession.new()
	_apply_session_header(session, sqlite_path)
	_apply_map_from_save(session, sqlite_path, report)
	var settlement := session.settlement

	var building_rows: Array = []
	for row in rows:
		if typeof(row) == TYPE_DICTIONARY and row.get("_skipped", false):
			report.buildings_truncated = true
			report.buildings_total_in_save = int(row.get("total_buildings", -1))
			continue
		if typeof(row) == TYPE_DICTIONARY:
			building_rows.append(row)
	report.buildings_extracted = building_rows.size()

	building_rows.sort_custom(func(a, b):
		if int(a["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return true
		if int(b["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return false
		return int(a["worldid"]) < int(b["worldid"])
	)
	for row in building_rows:
		if typeof(row) != TYPE_DICTIONARY:
			report.record_rejection("invalid_row")
			continue
		var bid := int(row.get("building_id", -1))
		if bid <= 0:
			report.record_rejection("invalid_building_id")
			continue
		if not ContentLoader.is_known_building_id(bid):
			report.record_rejection("unknown_building_type")
			continue
		var cmd := BuildCommand.new(
			bid, int(row["x"]), int(row["y"]), session.island, settlement
		)
		cmd.forced_worldid = int(row["worldid"])
		cmd.skip_cost = true
		cmd.defer_producer = true
		cmd.defer_collecting = true
		var placed: Variant = cmd.execute(session)
		if placed == null:
			report.record_rejection("placement_failed")
		else:
			report.buildings_placed += 1

	_apply_storage_rows(session, sqlite_path, report)
	_attach_deferred_producers(session)
	_apply_production_rows(session, sqlite_path, report)
	_apply_collector_rows(session, sqlite_path, report)
	_apply_unit_rows(session, sqlite_path, report)

	report.partial = (
		report.buildings_truncated
		or report.buildings_rejected > 0
		or report.buildings_placed < report.buildings_extracted
		or report.storage_rows_skipped > 0
		or report.production_rows_skipped > 0
		or report.collectors_unsupported > 0
		or report.collectors_unsupported_no_collecting_yaml > 0
		or report.collectors_skipped_yaml_duplicate > 0
	)
	session.set_meta(META_REPORT, report.to_dictionary())
	return {"ok": true, "error": "", "session": session, "report": report}


static func _apply_session_header(session: GameSession, sqlite_path: String) -> void:
	var json_text := _run_python_extract(
		EXTRACT_SESSION_SCRIPT,
		sqlite_path,
		"user://sqlite_session_extract.json",
	)
	if json_text.is_empty():
		return
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	session.restore_save_header(
		int(data.get("next_worldid", 1)),
		int(data.get("estimated_cur_tick", -1)),
	)


static func _extract_metadata_json(sqlite_path: String) -> Dictionary:
	var json_text := _run_python_extract(
		EXTRACT_METADATA_SCRIPT,
		sqlite_path,
		"user://sqlite_metadata_extract.json",
	)
	if json_text.is_empty():
		return {}
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func _apply_map_from_save(session: GameSession, sqlite_path: String, report: SqliteImportReport) -> void:
	var meta := _extract_metadata_json(sqlite_path)
	var map_name := str(meta.get("map_name", ""))
	var map_id := MapLoader.legacy_map_name_to_id(map_name)
	report.map_id = map_id
	if map_id.is_empty():
		session.load_test_map()
		return
	MapLoader.apply_map_to_session(session, map_id)


static func _attach_deferred_producers(session: GameSession) -> void:
	for building in session.get_buildings_on_island(session.island):
		if building.producer != null:
			continue
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(building.building_id)
		)
		ComponentFactory.attach_to_building(building, session, export, true, false, true)


static func _legacy_settlement_rowids(sqlite_path: String) -> Dictionary:
	var json_text := _run_python_extract(
		EXTRACT_SETTLEMENT_SCRIPT,
		sqlite_path,
		"user://sqlite_settlement_extract.json",
	)
	if json_text.is_empty():
		return {}
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return {}
	var ids: Dictionary = {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		ids[int(row.get("rowid", -1))] = true
	return ids


static func _apply_storage_rows(session: GameSession, sqlite_path: String, report: SqliteImportReport) -> void:
	var json_text := _run_python_extract(
		EXTRACT_STORAGE_SCRIPT,
		sqlite_path,
		"user://sqlite_storage_extract.json",
		["5000"],
	)
	if json_text.is_empty():
		return
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return
	report.storage_rows_total = rows.size()
	var settlement_rowids := _legacy_settlement_rowids(sqlite_path)
	var by_worldid: Dictionary = {}
	for b in session.get_buildings_on_island(session.island):
		by_worldid[b.worldid] = b
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			report.storage_rows_skipped += 1
			continue
		var wid := int(row.get("worldid", -1))
		var res_id := int(row.get("resource_id", -1))
		var amount := int(row.get("amount", 0))
		if res_id < 0 or amount == 0:
			report.storage_rows_skipped += 1
			continue
		if settlement_rowids.has(wid):
			var inv := session.settlement.inventory
			if not inv.has_resource_slot(res_id):
				inv.add_resource_slot(res_id, 999999)
			inv.alter(res_id, amount)
			report.settlement_storage_rows_applied += 1
			continue
		if not by_worldid.has(wid):
			report.storage_rows_skipped += 1
			continue
		var building: Building = by_worldid[wid]
		var storage := building.get_storage()
		if storage == null:
			report.storage_rows_skipped += 1
			continue
		storage.alter(res_id, amount)
		report.storage_rows_applied += 1


static func _apply_production_rows(session: GameSession, sqlite_path: String, report: SqliteImportReport) -> void:
	var json_text := _run_python_extract(
		EXTRACT_PRODUCTION_SCRIPT,
		sqlite_path,
		"user://sqlite_production_extract.json",
		["10000"],
	)
	if json_text.is_empty():
		return
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return
	report.production_rows_total = rows.size()
	var touched_producers: Array = []
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			report.production_rows_skipped += 1
			continue
		var owner_wid := int(row.get("owner_worldid", -1))
		var prod_line_id := int(row.get("prod_line_id", -1))
		var building: Building = session.get_building(owner_wid)
		if building == null or building.producer == null:
			report.production_rows_skipped += 1
			continue
		var producer: Producer = building.producer
		var production := producer.ensure_production_line(prod_line_id)
		if production == null:
			report.production_rows_skipped += 1
			continue
		var pause_old := int(row.get("pause_old_state", -1))
		production.restore_from_legacy_save(
			int(row.get("state", ProductionStates.NONE)),
			int(row.get("remaining_ticks", 0)),
			pause_old,
			int(row.get("creation_tick", 0)),
		)
		if producer not in touched_producers:
			touched_producers.append(producer)
		report.production_rows_applied += 1
	for producer in touched_producers:
		producer.sync_production_buckets()


static func _extract_unit_rows(sqlite_path: String) -> Array:
	var json_text := _run_python_extract(
		EXTRACT_UNITS_SCRIPT,
		sqlite_path,
		"user://sqlite_units_extract.json",
		["5000"],
	)
	if json_text.is_empty():
		return []
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return []
	return rows


static func _apply_collector_rows(session: GameSession, sqlite_path: String, report: SqliteImportReport) -> void:
	var rows: Array = _extract_unit_rows(sqlite_path)
	var by_home: Dictionary = {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str(row.get("kind", "")) != "collector":
			continue
		report.collector_rows_in_save += 1
		var home_id := int(row.get("home_building_worldid", -1))
		if home_id < 0:
			report.collectors_unsupported += 1
			continue
		if not by_home.has(home_id):
			by_home[home_id] = []
		by_home[home_id].append(row)

	for home_id_key in by_home.keys():
		var home_id: int = int(home_id_key)
		var save_rows: Array = by_home[home_id_key]
		var building: Building = session.get_building(home_id)
		if building == null:
			report.collectors_unsupported += save_rows.size()
			continue
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(building.building_id)
		)
		var specs := ContentLoader.create_collecting_from_export(export)
		if specs.is_empty():
			report.collectors_unsupported_no_collecting_yaml += save_rows.size()
			continue
		CollectingComponent.attach_from_save_rows(building, session, specs, save_rows)
		report.collectors_save_homes += 1
		report.collectors_restored += save_rows.size()

	_attach_deferred_yaml_collecting(session, by_home)


static func _attach_deferred_yaml_collecting(session: GameSession, save_homes: Dictionary) -> void:
	for building in session.get_buildings_on_island(session.island):
		if building.collecting != null:
			continue
		if save_homes.has(int(building.worldid)):
			continue
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(building.building_id)
		)
		var collecting := ContentLoader.create_collecting_from_export(export)
		if collecting.is_empty():
			continue
		building.collecting = CollectingComponent.new(building, session, collecting)


static func _apply_unit_rows(session: GameSession, sqlite_path: String, report: SqliteImportReport) -> void:
	var rows: Array = _extract_unit_rows(sqlite_path)
	report.unit_rows_total = rows.size()
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var kind := str(row.get("kind", "unit"))
		if kind == "wild_animal":
			var wid := int(row.get("worldid", -1))
			var x := int(row.get("x", 0))
			var y := int(row.get("y", 0))
			session.spawn_wild_animal(session.island, x, y, wid)
			report.wild_animals_spawned += 1
		elif kind == "collector":
			pass
		else:
			report.collectors_unsupported += 1
