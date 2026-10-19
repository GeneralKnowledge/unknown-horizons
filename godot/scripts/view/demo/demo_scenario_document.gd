class_name DemoScenarioDocument
extends RefCounted

## Unified demo scenario JSON (schema v1) for showcase boot and playable objectives.

const SCHEMA_VERSION := 1

var raw: Dictionary = {}
var last_boot_stats: Dictionary = {}


static func load_file(path: String) -> DemoScenarioDocument:
	var doc := DemoScenarioDocument.new()
	doc.raw = DemoScenarioRunner.load_dict(path)
	return doc


static func from_dict(data: Dictionary) -> DemoScenarioDocument:
	var doc := DemoScenarioDocument.new()
	doc.raw = data if data else {}
	return doc


func is_empty() -> bool:
	return raw.is_empty()


func schema_version() -> int:
	return int(raw.get("schema_version", 0))


func kind() -> String:
	return str(raw.get("kind", "showcase"))


func id() -> String:
	return str(raw.get("id", raw.get("demo_id", "unnamed")))


func validate() -> Array[String]:
	var errors: Array[String] = []
	if raw.is_empty():
		errors.append("empty document")
		return errors
	var ver := schema_version()
	if ver != 0 and ver != SCHEMA_VERSION:
		errors.append("unsupported schema_version %d" % ver)
	if kind() == "playable":
		if typeof(raw.get("steps", [])) != TYPE_ARRAY:
			errors.append("playable kind requires steps array")
	return errors


func boot_session(warmup_seconds: float = -1.0) -> GameSession:
	last_boot_stats = {"placed": 0, "failed": 0, "failed_labels": []}
	if not validate().is_empty() and schema_version() != 0:
		push_warning("DemoScenarioDocument: %s" % ", ".join(validate()))
	var map_id := str(raw.get("map_id", raw.get("map", DemoConfig.default_map_id())))
	var session := GameSession.new()
	if map_id == "test_island_20x20" or map_id == "test_island_20x20_simple":
		session.load_test_map()
	else:
		MapLoader.apply_map_to_session(session, map_id)
	var settlement_cfg: Dictionary = raw.get("settlement", {})
	var settle_xy := Vector2i(
		int(settlement_cfg.get("x", DemoConfig.default_settlement_point().x)),
		int(settlement_cfg.get("y", DemoConfig.default_settlement_point().y))
	)
	GameTestHelpers.new_settlement(session, settle_xy)
	_apply_starting_inventory(session)
	_apply_chain(session)
	_apply_placements(session, raw.get("placements", []), false)
	_apply_placements(session, raw.get("dlc_placements", []), false)
	_apply_placements(session, raw.get("ownerless_placements", []), true)
	_seed_building_storage(session)
	var warmup := warmup_seconds
	if warmup < 0.0:
		warmup = float(raw.get("sim_warmup_seconds", 35.0))
	if warmup > 0.0:
		session.run_seconds(warmup)
	last_boot_stats["building_count"] = session.get_buildings_on_island(session.island).size()
	return session


func camera_spot(spot_id: String) -> Dictionary:
	return DemoScenarioRunner.camera_spot(raw, spot_id)


func steps() -> Array:
	var s: Variant = raw.get("steps", [])
	if typeof(s) != TYPE_ARRAY:
		return []
	return s


func _apply_starting_inventory(session: GameSession) -> void:
	var inv: Variant = raw.get("starting_inventory", {})
	if typeof(inv) != TYPE_DICTIONARY:
		var legacy_gold: Variant = raw.get("starting_gold", null)
		if legacy_gold != null:
			session.settlement.inventory.alter(
				int(GameConstants.RES["GOLD"]),
				int(legacy_gold) - session.settlement.inventory.amount(int(GameConstants.RES["GOLD"]))
			)
		return
	for res_name in inv.keys():
		if not GameConstants.RES.has(str(res_name)):
			continue
		var res_id := int(GameConstants.RES[str(res_name)])
		var want: int = int(inv[res_name])
		session.settlement.inventory.alter(res_id, want - session.settlement.inventory.amount(res_id))


func _apply_chain(session: GameSession) -> void:
	DemoScenarioRunner.apply_chain_dict(session, raw.get("chain", {}))


func _apply_placements(session: GameSession, list: Variant, ownerless: bool) -> void:
	if typeof(list) != TYPE_ARRAY:
		return
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name := str(entry.get("building", ""))
		var bid := DemoScenarioRunner.building_id_for_name(name)
		if bid < 0:
			_record_fail(name)
			continue
		var at := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		var built: Building = null
		if ownerless:
			built = DemoScenarioRunner.build_ownerless_at(session, bid, at)
		else:
			built = DemoScenarioRunner.build_at(session, bid, at)
		if built == null:
			_record_fail("%s@%s" % [name, str(at)])
		else:
			last_boot_stats["placed"] = int(last_boot_stats["placed"]) + 1


func _seed_building_storage(session: GameSession) -> void:
	DemoScenarioRunner.seed_building_storage_list(session, raw.get("seed_building_storage", []))


func _record_fail(label: String) -> void:
	last_boot_stats["failed"] = int(last_boot_stats["failed"]) + 1
	var arr: Array = last_boot_stats.get("failed_labels", [])
	arr.append(label)
	last_boot_stats["failed_labels"] = arr
