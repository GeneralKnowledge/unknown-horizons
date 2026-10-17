class_name SqliteSaveLoader
extends RefCounted

## Legacy UH savegames (.sqlite). Subset load via Python extract + BuildCommand replay.

const MAGIC := "SQLite format 3"
const EXTRACT_SCRIPT := "development/godot/sqlite_extract_buildings.py"


static func is_sqlite_file(path: String) -> bool:
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


static func _extract_buildings_json(sqlite_path: String) -> String:
	var tmp := "user://sqlite_buildings_extract.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var script := _repo_root().path_join(EXTRACT_SCRIPT)
	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[script, sqlite_path, tmp_abs, "200"],
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
	if not is_sqlite_file(path):
		push_error("Not a sqlite save: %s" % path)
		return null
	var json_text := _extract_buildings_json(path)
	if json_text.is_empty():
		return null
	var rows: Variant = JSON.parse_string(json_text)
	if typeof(rows) != TYPE_ARRAY:
		return null
	var session := GameSession.new()
	session.load_test_map()
	var settlement := session.settlement
	rows.sort_custom(func(a, b):
		if int(a["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return true
		if int(b["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return false
		return int(a["worldid"]) < int(b["worldid"])
	)
	for row in rows:
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
	return session
