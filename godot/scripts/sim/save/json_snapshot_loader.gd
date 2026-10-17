class_name JsonSnapshotLoader
extends RefCounted

## Loads a GameSession from an in-memory snapshot dictionary.


static func load_from_dict(data: Dictionary) -> GameSession:
	var session := GameSession.new()
	session.load_test_map()
	session.load_snapshot(data)
	return session


static func load_from_file(path: String) -> GameSession:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	assert(typeof(data) == TYPE_DICTIONARY, "Snapshot JSON must be an object")
	return load_from_dict(data)
