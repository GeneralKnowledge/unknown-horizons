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


static func legacy_map_name_to_id(legacy_name: String) -> String:
	var raw := legacy_name.strip_edges()
	if raw.is_empty():
		return ""
	var candidate := raw.to_lower().replace("-", "_").replace(" ", "_")
	for entry in list_maps():
		if str(entry.get("id", "")) == candidate:
			return candidate
	# Common legacy map_name values (hyphenated) not yet in manifest id form.
	match raw.to_lower():
		"test-map-tiny":
			return "test_map_tiny"
		"development":
			return "development"
		"quattro":
			return "quattro"
	return ""


static func load_ground_for_map(map_id: String) -> Dictionary:
	for entry in list_maps():
		if str(entry.get("id", "")) != map_id:
			continue
		var loader := str(entry.get("loader", ""))
		if loader == "ground_json":
			var ground_path := str(entry.get("ground", ""))
			if ground_path.begins_with("res://"):
				return _load_ground_json_file(ground_path)
		elif loader == "stub_test_island":
			return TestMapFactory.create_ground_map()
	match map_id:
		"test_island_20x20", "test_island_20x20_simple":
			return TestMapFactory.create_ground_map()
		_:
			push_warning("Unknown map id %s; using default ground" % map_id)
			return TestMapFactory.create_ground_map()


static func _load_ground_json_file(res_path: String) -> Dictionary:
	if not FileAccess.file_exists(res_path):
		push_warning("Missing ground file %s" % res_path)
		return TestMapFactory.create_ground_map()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(res_path))
	if typeof(data) != TYPE_DICTIONARY:
		return TestMapFactory.create_ground_map()
	var ground: Dictionary = {}
	for tile in data.get("tiles", []):
		if typeof(tile) != TYPE_ARRAY or tile.size() < 3:
			continue
		var coords := Vector2i(int(tile[0]), int(tile[1]))
		ground[coords] = int(tile[2])
	if ground.is_empty():
		return TestMapFactory.create_ground_map()
	return ground


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
