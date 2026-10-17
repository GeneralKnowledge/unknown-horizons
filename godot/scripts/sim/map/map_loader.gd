class_name MapLoader
extends RefCounted

## Loads bundled map entries from maps_manifest.json (ground data via stubs for now).

const MANIFEST_PATH := "res://resources/maps/maps_manifest.json"
const USER_MANIFEST_PATH := "user://maps/maps_manifest.json"
const DEFAULT_MAP_ID := "test_island_20x20"


static func list_maps() -> Array:
	var maps: Array = []
	maps.append_array(_read_manifest().get("maps", []))
	if FileAccess.file_exists(USER_MANIFEST_PATH):
		maps.append_array(_read_json_file(USER_MANIFEST_PATH).get("maps", []))
	return maps


static func default_map_id() -> String:
	return DEFAULT_MAP_ID


static func load_ground_for_map(map_id: String) -> Dictionary:
	match map_id:
		"test_island_20x20", "test_island_20x20_simple":
			return TestMapFactory.create_ground_map()
		_:
			push_warning("Unknown map id %s; using default ground" % map_id)
			return TestMapFactory.create_ground_map()


static func apply_map_to_session(session: GameSession, map_id: String) -> void:
	session.island.load_ground(load_ground_for_map(map_id))
	session.settlement.init_buildability()


static func _read_manifest() -> Dictionary:
	return _read_json_file(MANIFEST_PATH)


static func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"maps": []}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {"maps": []}
	return data
