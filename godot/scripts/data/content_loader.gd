class_name ContentLoader
extends RefCounted

const BUILDINGS_JSON := "res://resources/exported/buildings.json"
const UNITS_JSON := "res://resources/exported/units.json"
const DLC_MANIFEST := "res://resources/dlc/northern_company/manifest.json"

static var _building_id_to_stem: Dictionary = {}
static var _unit_id_to_stem: Dictionary = {}
static var _stem_to_json_path: Dictionary = {}
static var _stem_loaded: bool = false


static func _index_buildings_file(json_path: String) -> void:
	if not FileAccess.file_exists(json_path):
		return
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	for stem in all.keys():
		_stem_to_json_path[stem] = json_path
		var export: Dictionary = all[stem]
		if export.has("dlc_building_id"):
			_building_id_to_stem[int(export["dlc_building_id"])] = stem
			continue
		var id_name: String = str(export.get("id_name", ""))
		if id_name.begins_with("BUILDINGS."):
			var const_name: String = id_name.substr(10)
			if GameConstants.BUILDINGS.has(const_name):
				_building_id_to_stem[int(GameConstants.BUILDINGS[const_name])] = stem


static func _index_units_file() -> void:
	if not FileAccess.file_exists(UNITS_JSON):
		return
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UNITS_JSON))
	for stem in all.keys():
		var export: Dictionary = all[stem]
		var id_name: String = str(export.get("id_name", ""))
		if id_name.begins_with("UNITS."):
			var const_name: String = id_name.substr(6)
			if GameConstants.UNITS.has(const_name):
				_unit_id_to_stem[int(GameConstants.UNITS[const_name])] = stem


static func _ensure_stem_index() -> void:
	if _stem_loaded:
		return
	_index_buildings_file(BUILDINGS_JSON)
	_index_units_file()
	for pack_id in ["northern_company"]:
		_index_buildings_file("res://resources/dlc/%s/buildings.json" % pack_id)
	_stem_loaded = true


static func is_dlc_building_id(building_id: int) -> bool:
	_ensure_stem_index()
	if not _building_id_to_stem.has(building_id):
		return false
	var stem: String = _building_id_to_stem[building_id]
	var path: String = str(_stem_to_json_path.get(stem, BUILDINGS_JSON))
	return path.find("/dlc/") >= 0


static func stem_for_unit_id(unit_id: int) -> String:
	_ensure_stem_index()
	if _unit_id_to_stem.has(unit_id):
		return str(_unit_id_to_stem[unit_id])
	push_error("Unknown unit id %s" % unit_id)
	return "deer"


static func stem_for_building_id(building_id: int) -> String:
	_ensure_stem_index()
	if _building_id_to_stem.has(building_id):
		return str(_building_id_to_stem[building_id])
	push_error("Unknown building id %s" % building_id)
	return "lumberjackcamp"


static func load_building_export(stem: String) -> Dictionary:
	_ensure_stem_index()
	var json_path: String = str(_stem_to_json_path.get(stem, BUILDINGS_JSON))
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	assert(all.has(stem), "Missing building export: %s in %s" % [stem, json_path])
	return all[stem]


static func resolve_res(value) -> int:
	if typeof(value) == TYPE_INT:
		return value
	var name := str(value)
	if name.is_valid_int():
		return int(name)
	if name.begins_with("RES."):
		name = name.substr(4)
	return int(GameConstants.RES[name])


static func create_storage_from_export(export: Dictionary) -> Inventory:
	var comp: Dictionary = export.get("components", {}).get("Storage", {})
	var cfg: Dictionary = comp.get("config", {})
	var slot_sizes: Dictionary = {}
	for res_key in cfg.get("slot_sizes", {}).keys():
		var res_id := resolve_res(res_key)
		slot_sizes[res_id] = int(cfg["slot_sizes"][res_key])
	if slot_sizes.is_empty() and str(comp.get("type", "")) == "SettlementStorage":
		return PositiveSizedSpecializedInventory.new({GameConstants.RES["GOLD"]: 999999})
	return PositiveSizedSpecializedInventory.new(slot_sizes)


static func create_collecting_from_export(export: Dictionary) -> Dictionary:
	var raw: Dictionary = export.get("components", {}).get("Collecting", {}).get("collectors", {})
	var normalized := {}
	for unit_id in raw.keys():
		normalized[int(unit_id)] = int(raw[unit_id])
	return normalized


static func load_unit_export(stem: String) -> Dictionary:
	assert(FileAccess.file_exists(UNITS_JSON), "Missing units export — run export_content.py")
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UNITS_JSON))
	assert(all.has(stem), "Missing unit export: %s" % stem)
	return all[stem]


static func create_storage_from_unit_export(export: Dictionary) -> Inventory:
	return create_storage_from_export(export)


static func create_producer_lines_from_unit(export: Dictionary) -> Dictionary:
	return create_producer_lines(export)


static func create_producer_lines(export: Dictionary) -> Dictionary:
	var raw: Dictionary = export.get("components", {}).get("Producer", {}).get("productionlines", {})
	var normalized := {}
	for line_id in raw.keys():
		var data: Dictionary = raw[line_id].duplicate(true)
		if data.has("produces"):
			var produces: Array = []
			for entry in data["produces"]:
				produces.append([resolve_res(entry[0]), int(entry[1])])
			data["produces"] = produces
		if data.has("consumes"):
			var consumes: Array = []
			for entry in data["consumes"]:
				consumes.append([resolve_res(entry[0]), int(entry[1])])
			data["consumes"] = consumes
		normalized[int(line_id)] = data
	return normalized
