class_name SaveLoader
extends RefCounted

## Entry point for savegame loading (JSON snapshots today, SQLite later).


static func load(path: String) -> GameSession:
	if path.ends_with(".json"):
		return JsonSnapshotLoader.load_from_file(path)
	if SqliteSaveLoader.is_sqlite_file(path):
		return SqliteSaveLoader.load(path)
	push_error("Unknown save format: %s" % path)
	return null


static func probe(path: String) -> Dictionary:
	if path.ends_with(".json"):
		return {"ok": FileAccess.file_exists(path), "format": "json", "implemented": true}
	if SqliteSaveLoader.is_sqlite_file(path):
		var info := SqliteSaveLoader.probe(path)
		info["format"] = "sqlite"
		return info
	return {"ok": false, "format": "unknown", "path": path}
