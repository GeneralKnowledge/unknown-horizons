class_name PlayableDemoConfig
extends RefCounted

const CONFIG_PATH := "res://resources/demo/playable_lumber_demo.json"

static var _cached: Dictionary = {}


static func load() -> Dictionary:
	if not _cached.is_empty():
		return _cached
	if not FileAccess.file_exists(CONFIG_PATH):
		_cached = _defaults()
		return _cached
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		_cached = _defaults()
	else:
		_cached = data
	return _cached


static func map_id() -> String:
	return str(load().get("map_id", DemoConfig.default_map_id()))


static func settlement_point() -> Vector2i:
	var cfg := load()
	var settle: Variant = cfg.get("settlement", {})
	if typeof(settle) == TYPE_DICTIONARY:
		return Vector2i(int(settle.get("x", 34)), int(settle.get("y", 34)))
	return DemoConfig.default_settlement_point()


static func target_boards() -> int:
	return maxi(1, int(load().get("target_boards_in_warehouse", 8)))


static func min_trees() -> int:
	return maxi(1, int(load().get("min_trees", 2)))


static func apply_starting_resources(settlement: Settlement) -> void:
	var cfg := load()
	if cfg.has("starting_gold"):
		settlement.inventory.alter(GameConstants.RES["GOLD"], int(cfg["starting_gold"]))
	if cfg.has("starting_tools"):
		settlement.inventory.alter(GameConstants.RES["TOOLS"], int(cfg["starting_tools"]))


static func _defaults() -> Dictionary:
	return {
		"map_id": "development",
		"settlement": {"x": 34, "y": 34},
		"target_boards_in_warehouse": 8,
		"min_trees": 2,
		"starting_gold": 500,
		"starting_tools": 20,
	}
