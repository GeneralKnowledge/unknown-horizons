class_name DemoScenarioRunner
extends RefCounted

## Apply bundled demo scenario JSON to a live session (PoC showcase + screenshot scene).


static func load_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DemoScenarioRunner: missing %s" % path)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("DemoScenarioRunner: invalid JSON at %s" % path)
		return {}
	return data


static func boot_from_resource(scenario_path: String, sim_warmup_seconds: float = -1.0) -> GameSession:
	var doc := DemoScenarioDocument.load_file(scenario_path)
	if doc.is_empty():
		return null
	return doc.boot_session(sim_warmup_seconds)


static func boot_from_dict(scenario: Dictionary, sim_warmup_seconds: float = -1.0) -> GameSession:
	var doc := DemoScenarioDocument.from_dict(scenario)
	return doc.boot_session(sim_warmup_seconds)


static func last_boot_stats_for_dict(scenario: Dictionary) -> Dictionary:
	var doc := DemoScenarioDocument.from_dict(scenario)
	doc.boot_session(0.0)
	return doc.last_boot_stats


static func camera_spot(scenario: Dictionary, spot_id: String) -> Dictionary:
	var spots: Variant = scenario.get("camera_spots", {})
	if typeof(spots) != TYPE_DICTIONARY:
		return {"x": 30, "y": 30, "zoom": 1.1}
	var spot: Variant = spots.get(spot_id, spots.get("wide", {}))
	if typeof(spot) != TYPE_DICTIONARY:
		return {"x": 30, "y": 30, "zoom": 1.1}
	return spot


static func apply_chain_dict(session: GameSession, chain: Dictionary) -> void:
	if chain.is_empty():
		return
	var settlement := session.settlement
	var island := session.island

	var lj_xy := _xy(chain, "lumberjack")
	if lj_xy != Vector2i.ZERO:
		build_at(session, GameConstants.BUILDINGS["LUMBERJACK"], lj_xy)

	var hunter_xy := _xy(chain, "hunter")
	if hunter_xy != Vector2i.ZERO:
		var hunter: Building = build_at(session, GameConstants.BUILDINGS["HUNTER"], hunter_xy)
		if hunter != null:
			hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)

	for deposit: Variant in chain.get("fish_deposits", []):
		if typeof(deposit) != TYPE_DICTIONARY:
			continue
		var school: Building = build_ownerless_at(
			session,
			GameConstants.BUILDINGS["FISH_DEPOSIT"],
			Vector2i(int(deposit.get("x", 0)), int(deposit.get("y", 0)))
		)
		if school != null and school.get_producer() != null:
			school.get_producer().finish_production_now()

	var fisher_xy := _xy(chain, "fisher")
	if fisher_xy != Vector2i.ZERO:
		build_at(session, GameConstants.BUILDINGS["FISHER"], fisher_xy)

	var clay_xy := _xy(chain, "clay_deposit")
	if clay_xy != Vector2i.ZERO:
		var deposit: Building = build_ownerless_at(session, GameConstants.BUILDINGS["CLAY_DEPOSIT"], clay_xy)
		if deposit != null:
			deposit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 10)

	var pit_xy := _xy(chain, "clay_pit")
	if pit_xy != Vector2i.ZERO:
		build_at(session, GameConstants.BUILDINGS["CLAY_PIT"], pit_xy)

	var yard_xy := _xy(chain, "brickyard")
	if yard_xy != Vector2i.ZERO:
		build_at(session, GameConstants.BUILDINGS["BRICKYARD"], yard_xy)


static func seed_building_storage_list(session: GameSession, list: Variant) -> void:
	if typeof(list) != TYPE_ARRAY:
		return
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name := str(entry.get("building", ""))
		var res_name := str(entry.get("resource", ""))
		if not GameConstants.RES.has(res_name):
			continue
		var bid := building_id_for_name(name)
		if bid < 0:
			continue
		var amount := int(entry.get("amount", 0))
		for b in session.get_buildings_on_island(session.island):
			if b.building_id != bid:
				continue
			b.get_storage().alter(int(GameConstants.RES[res_name]), amount)
			break


static func building_id_for_name(name: String) -> int:
	if GameConstants.BUILDINGS.has(name):
		return int(GameConstants.BUILDINGS[name])
	if DlcConstants.BUILDINGS.has(name):
		return int(DlcConstants.BUILDINGS[name])
	return -1


static func build_at(session: GameSession, building_id: int, at: Vector2i) -> Building:
	var cmd := BuildCommand.new(
		building_id, at.x, at.y, session.island, session.settlement
	)
	cmd.skip_cost = true
	return cmd.execute(session) as Building


static func build_ownerless_at(session: GameSession, building_id: int, at: Vector2i) -> Building:
	var cmd := BuildCommand.new(building_id, at.x, at.y, session.island, null, true)
	cmd.skip_cost = true
	return cmd.execute(session) as Building


static func _xy(chain: Dictionary, key: String) -> Vector2i:
	var node: Variant = chain.get(key, {})
	if typeof(node) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(node.get("x", 0)), int(node.get("y", 0)))
