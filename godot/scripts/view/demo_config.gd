class_name DemoConfig
extends RefCounted

const CONFIG_PATH := "res://resources/demo/demo_config.json"

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


static func default_map_id() -> String:
	return str(load_config().get("default_map_id", "development"))


static func default_settlement_point() -> Vector2i:
	var cfg := load_config()
	return Vector2i(int(cfg.get("default_settlement_x", 34)), int(cfg.get("default_settlement_y", 34)))


static func show_start_menu() -> bool:
	return bool(load_config().get("show_start_menu", true))


static func title() -> String:
	return str(load_config().get("title", "Unknown Horizons"))


static func subtitle() -> String:
	return str(load_config().get("subtitle", ""))


static func theme_pack_id() -> String:
	return str(load_config().get("theme_pack_id", "")).strip_edges()


static func showcase_scenario_path() -> String:
	return str(load_config().get("showcase_scenario", "res://resources/demo/starter_tier1_scenario.json"))


static func apply_theme_pack_if_configured() -> void:
	var pid := theme_pack_id()
	if not pid.is_empty():
		ContentTheme.apply_pack_override(pid)


static func _defaults() -> Dictionary:
	return {
		"default_map_id": "development",
		"default_settlement_x": 34,
		"default_settlement_y": 34,
		"show_start_menu": true,
		"title": "Unknown Horizons",
		"subtitle": "",
		"theme_pack_id": "",
		"showcase_scenario": "res://resources/demo/starter_tier1_scenario.json",
	}
