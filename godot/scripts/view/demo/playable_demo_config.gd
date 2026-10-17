class_name PlayableDemoConfig
extends RefCounted

const CONFIG_PATH := "res://resources/demo/playable_lumber_demo.json"

static var _cached: Dictionary = {}


static func load_config() -> Dictionary:
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
	return str(load_config().get("map_id", DemoConfig.default_map_id()))


static func settlement_point() -> Vector2i:
	var cfg := load_config()
	var settle: Variant = cfg.get("settlement", {})
	if typeof(settle) == TYPE_DICTIONARY:
		return Vector2i(int(settle.get("x", 34)), int(settle.get("y", 34)))
	return DemoConfig.default_settlement_point()


static func steps() -> Array:
	var raw: Variant = load_config().get("steps", [])
	if typeof(raw) != TYPE_ARRAY:
		return _defaults()["steps"]
	return raw


static func clay_deposit_cfg() -> Dictionary:
	var raw: Variant = load_config().get("clay_deposit", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


static func clay_deposit_point() -> Vector2i:
	var cfg := clay_deposit_cfg()
	return Vector2i(int(cfg.get("x", 33)), int(cfg.get("y", 33)))


static func apply_starting_resources(settlement: Settlement) -> void:
	var cfg := load_config()
	if cfg.has("starting_gold"):
		settlement.inventory.alter(GameConstants.RES["GOLD"], int(cfg["starting_gold"]))
	if cfg.has("starting_tools"):
		settlement.inventory.alter(GameConstants.RES["TOOLS"], int(cfg["starting_tools"]))
	if cfg.has("starting_boards"):
		settlement.inventory.alter(GameConstants.RES["BOARDS"], int(cfg["starting_boards"]))


static func _defaults() -> Dictionary:
	return {
		"map_id": "development",
		"settlement": {"x": 30, "y": 30},
		"clay_deposit": {"x": 33, "y": 33, "spawn_at_start": true, "seed_raw_clay": 12},
		"steps": [
			{
				"id": "boards",
				"resource": "BOARDS",
				"warehouse_amount": 8,
				"min_trees": 2,
				"require_lumberjack": true,
			},
			{
				"id": "bricks",
				"resource": "BRICKS",
				"warehouse_amount": 4,
				"require_buildings": ["CLAY_PIT", "BRICKYARD"],
			},
		],
		"starting_gold": 900,
		"starting_tools": 30,
		"starting_boards": 12,
	}
