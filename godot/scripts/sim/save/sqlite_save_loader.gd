class_name SqliteSaveLoader
extends RefCounted

## Legacy UH savegames (.sqlite). Full sim mapping is not implemented yet.

const MAGIC := "SQLite format 3"


static func is_sqlite_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var header := f.get_buffer(16).get_string_from_ascii()
	f.close()
	return header.begins_with(MAGIC)


static func probe(path: String) -> Dictionary:
	if not is_sqlite_file(path):
		return {"ok": false, "error": "not_sqlite", "path": path}
	return {
		"ok": true,
		"implemented": false,
		"path": path,
		"message": "SQLite save load not implemented — use sqlite_save_smoke.py in CI",
	}


static func load(_path: String) -> GameSession:
	push_warning("SqliteSaveLoader.load is not implemented yet")
	return null
