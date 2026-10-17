class_name SqliteSaveLoader
extends RefCounted

## Legacy UH savegames (.sqlite). Subset load via Python extract + BuildCommand replay.

const MAGIC := "SQLite format 3"
const EXTRACT_BUILDINGS_SCRIPT := "development/godot/sqlite_extract_buildings.py"
const EXTRACT_STORAGE_SCRIPT := "development/godot/sqlite_extract_storage.py"
const EXTRACT_METADATA_SCRIPT := "development/godot/sqlite_extract_metadata.py"
const PREPARE_SAVE_SCRIPT := "development/godot/sqlite_prepare_save.py"
const DEFAULT_BUILDING_LIMIT := 500


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


static func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func _prepare_sqlite_path(path: String) -> String:
	if not path.ends_with(".sqlite.bz2"):
		return path
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


static func _extract_buildings_json(sqlite_path: String, limit: int = DEFAULT_BUILDING_LIMIT) -> String:
	if OS.has_feature("web"):
		push_error("SQLite save import is not supported in browser builds; use JSON snapshots.")
		return ""
	var tmp := "user://sqlite_buildings_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var script := _repo_root().path_join(EXTRACT_BUILDINGS_SCRIPT)
	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[script, sqlite_path, tmp_abs, str(limit)],
		output,
		true
	)
	if exit_code != 0:
		push_error("sqlite_extract_buildings failed: %s" % str(output))
		return ""
	if not FileAccess.file_exists(tmp):
		return ""
	return FileAccess.get_file_as_string(tmp)


static func probe(path: String) -> Dictionary:
	if not is_sqlite_file(path):
		return {"ok": false, "error": "not_sqlite", "path": path}
	var rows := _extract_buildings_json(path)
	var count := 0
	if not rows.is_empty():
		var data: Variant = JSON.parse_string(rows)
		if typeof(data) == TYPE_ARRAY:
			count = data.size()
	return {
		"ok": true,
		"implemented": count > 0,
		"path": path,
		"building_rows": count,
		"message": "Subset load via sqlite_extract_buildings.py",
	}


static func load(path: String) -> GameSession:
	if OS.has_feature("web"):
		push_error("SQLite save import is not supported in browser builds.")
		return null
	if not is_sqlite_file(path):
		push_error("Not a sqlite save: %s" % path)
		return null
	var sqlite_path := _prepare_sqlite_path(path)
	if sqlite_path.is_empty():
		sqlite_path = path
	var json_text := _extract_buildings_json(sqlite_path)
	if json_text.is_empty():
		return null
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return null
	var session := GameSession.new()
	_apply_map_from_save(session, sqlite_path)
	var settlement := session.settlement
	rows.sort_custom(func(a, b):
		if int(a["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return true
		if int(b["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return false
		return int(a["worldid"]) < int(b["worldid"])
	)
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY or row.get("_skipped", false):
			continue
		var bid := int(row["building_id"])
		if bid <= 0:
			continue
		if not ContentLoader.stem_for_building_id(bid):
			continue
		var cmd := BuildCommand.new(
			bid, int(row["x"]), int(row["y"]), session.island, settlement
		)
		cmd.forced_worldid = int(row["worldid"])
		cmd.execute(session)
	_apply_storage_rows(session, sqlite_path)
	return session


static func _extract_metadata_json(sqlite_path: String) -> Dictionary:
	var tmp := "user://sqlite_metadata_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var script := _repo_root().path_join(EXTRACT_METADATA_SCRIPT)
	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[script, sqlite_path, tmp_abs],
		output,
		true
	)
	if exit_code != 0 or not FileAccess.file_exists(tmp):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func _apply_map_from_save(session: GameSession, sqlite_path: String) -> void:
	var meta := _extract_metadata_json(sqlite_path)
	var map_name := str(meta.get("map_name", ""))
	var map_id := MapLoader.legacy_map_name_to_id(map_name)
	if map_id.is_empty():
		session.load_test_map()
		return
	MapLoader.apply_map_to_session(session, map_id)


static func _extract_storage_json(sqlite_path: String) -> String:
	if OS.has_feature("web"):
		return ""
	var tmp := "user://sqlite_storage_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var script := _repo_root().path_join(EXTRACT_STORAGE_SCRIPT)
	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[script, sqlite_path, tmp_abs, "5000"],
		output,
		true
	)
	if exit_code != 0:
		push_warning("sqlite_extract_storage failed: %s" % str(output))
		return ""
	if not FileAccess.file_exists(tmp):
		return ""
	return FileAccess.get_file_as_string(tmp)


static func _apply_storage_rows(session: GameSession, sqlite_path: String) -> void:
	var json_text := _extract_storage_json(sqlite_path)
	if json_text.is_empty():
		return
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return
	var by_worldid: Dictionary = {}
	for b in session.get_buildings_on_island(session.island):
		by_worldid[b.worldid] = b
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var wid := int(row.get("worldid", -1))
		if not by_worldid.has(wid):
			continue
		var building: Building = by_worldid[wid]
		var storage := building.get_storage()
		if storage == null:
			continue
		var res_id := int(row.get("resource_id", -1))
		var amount := int(row.get("amount", 0))
		if res_id < 0 or amount == 0:
			continue
		storage.alter(res_id, amount)
