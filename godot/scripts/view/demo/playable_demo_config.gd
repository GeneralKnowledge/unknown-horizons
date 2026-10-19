class_name PlayableDemoConfig
extends RefCounted

const PATH_SHORT := "res://resources/demo/playable_lumber_demo.json"
const PATH_EXPEDITION := "res://resources/demo/playable_northern_expedition.json"

static var _active_path: String = PATH_SHORT
static var _cached: Dictionary = {}


static func use_short_demo() -> void:
	_active_path = PATH_SHORT
	_cached.clear()


static func use_expedition_demo() -> void:
	_active_path = PATH_EXPEDITION
	_cached.clear()


static func active_profile_id() -> String:
	return str(load_config().get("demo_id", "playable_lumber"))


static func snapshot_key() -> String:
	return active_profile_id()


static func set_profile_from_snapshot(demo: Dictionary) -> void:
	if demo.has("playable_northern_expedition"):
		use_expedition_demo()
	elif demo.has("playable_lumber"):
		use_short_demo()
	else:
		var profile := str(demo.get("profile", "short"))
		if profile == "expedition" or profile == "northern_expedition":
			use_expedition_demo()
		else:
			use_short_demo()


static func load_config() -> Dictionary:
	if not _cached.is_empty():
		return _cached
	var path := _active_path
	if not FileAccess.file_exists(path):
		_cached = _defaults()
		return _cached
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
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


static func world_hints() -> Dictionary:
	var raw: Variant = load_config().get("world_hints", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


static func clay_deposit_cfg() -> Dictionary:
	var raw: Variant = load_config().get("clay_deposit", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


static func clay_deposit_point() -> Vector2i:
	var cfg := clay_deposit_cfg()
	if cfg.is_empty():
		var hints := world_hints()
		var clay: Variant = hints.get("clay_deposit", {})
		if typeof(clay) == TYPE_DICTIONARY:
			return Vector2i(int(clay.get("x", 33)), int(clay.get("y", 33)))
	return Vector2i(int(cfg.get("x", 33)), int(cfg.get("y", 33)))


static func hint_point_for_step(step_id: String) -> Vector2i:
	var hints := world_hints()
	var node: Variant = hints.get(step_id, {})
	if typeof(node) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(node.get("x", 0)), int(node.get("y", 0)))


static func apply_starting_resources(settlement: Settlement) -> void:
	var cfg := load_config()
	if cfg.has("starting_gold"):
		var gold_id := int(GameConstants.RES["GOLD"])
		settlement.inventory.alter(gold_id, int(cfg["starting_gold"]) - settlement.inventory.amount(gold_id))
	if cfg.has("starting_tools"):
		var tools_id := int(GameConstants.RES["TOOLS"])
		settlement.inventory.alter(tools_id, int(cfg["starting_tools"]) - settlement.inventory.amount(tools_id))
	if cfg.has("starting_boards"):
		var boards_id := int(GameConstants.RES["BOARDS"])
		settlement.inventory.alter(boards_id, int(cfg["starting_boards"]) - settlement.inventory.amount(boards_id))
	var extra: Variant = cfg.get("starting_inventory", {})
	if typeof(extra) == TYPE_DICTIONARY:
		for res_name in extra.keys():
			if not GameConstants.RES.has(str(res_name)):
				continue
			var res_id := int(GameConstants.RES[str(res_name)])
			var want := int(extra[res_name])
			settlement.inventory.alter(res_id, want - settlement.inventory.amount(res_id))


static func success_message() -> String:
	return str(
		load_config().get(
			"success_message",
			"Lumber and bricks are in the warehouse — the tier‑2 chain works. "
			+ "Keep building or save JSON to continue later."
		)
	)


static func _defaults() -> Dictionary:
	return {
		"demo_id": "playable_lumber",
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
