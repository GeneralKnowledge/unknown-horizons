class_name JsonSnapshotLoader
extends RefCounted

## Loads a GameSession from an in-memory snapshot dictionary.


static func try_load_from_dict(data: Dictionary) -> Dictionary:
	var session := GameSession.new()
	session.load_test_map()
	var result := session.try_load_snapshot(data)
	if not result["ok"]:
		return {"ok": false, "error": str(result.get("error", "")), "session": null}
	return {"ok": true, "error": "", "session": session}


static func load_from_dict(data: Dictionary) -> GameSession:
	var result := try_load_from_dict(data)
	if not result["ok"]:
		push_error("JsonSnapshotLoader: %s" % result.get("error", ""))
		return null
	return result["session"]


static func load_from_file(path: String) -> GameSession:
	if not FileAccess.file_exists(path):
		push_error("Missing snapshot file: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Snapshot JSON must be an object")
		return null
	return load_from_dict(data)
