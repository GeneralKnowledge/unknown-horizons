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


static func boot_from_resource(scenario_path: String, sim_warmup_seconds: float = 35.0) -> GameSession:
	var scenario := load_dict(scenario_path)
	if scenario.is_empty():
		return null
	return boot_from_dict(scenario, sim_warmup_seconds)


static func boot_from_dict(scenario: Dictionary, sim_warmup_seconds: float = 35.0) -> GameSession:
	var map_id := str(scenario.get("map_id", DemoConfig.default_map_id()))
	var session := GameSession.new()
	MapLoader.apply_map_to_session(session, map_id)
	var settlement_cfg: Dictionary = scenario.get("settlement", {})
	var settle_xy := Vector2i(
		int(settlement_cfg.get("x", DemoConfig.default_settlement_point().x)),
		int(settlement_cfg.get("y", DemoConfig.default_settlement_point().y))
	)
	GameTestHelpers.new_settlement(session, settle_xy)
	_apply_chain(session, scenario.get("chain", {}))
	if sim_warmup_seconds > 0.0:
		session.run_seconds(sim_warmup_seconds)
	return session


static func _apply_chain(session: GameSession, chain: Dictionary) -> void:
	if chain.is_empty():
		return
	var settlement := session.settlement
	var island := session.island

	var lj_xy := _xy(chain, "lumberjack")
	if lj_xy != Vector2i.ZERO:
		_build(session, GameConstants.BUILDINGS["LUMBERJACK"], lj_xy, settlement, island)

	var hunter_xy := _xy(chain, "hunter")
	if hunter_xy != Vector2i.ZERO:
		var hunter: Building = _build(
			session, GameConstants.BUILDINGS["HUNTER"], hunter_xy, settlement, island
		)
		if hunter != null:
			hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)

	for deposit: Variant in chain.get("fish_deposits", []):
		if typeof(deposit) != TYPE_DICTIONARY:
			continue
		var school: Building = _build_ownerless_cmd(
			session,
			GameConstants.BUILDINGS["FISH_DEPOSIT"],
			Vector2i(int(deposit.get("x", 0)), int(deposit.get("y", 0)))
		)
		if school != null and school.get_producer() != null:
			school.get_producer().finish_production_now()

	var fisher_xy := _xy(chain, "fisher")
	if fisher_xy != Vector2i.ZERO:
		_build(session, GameConstants.BUILDINGS["FISHER"], fisher_xy, settlement, island)

	var clay_xy := _xy(chain, "clay_deposit")
	if clay_xy != Vector2i.ZERO:
		var deposit: Building = _build_ownerless_cmd(
			session, GameConstants.BUILDINGS["CLAY_DEPOSIT"], clay_xy
		)
		if deposit != null:
			deposit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 10)

	var pit_xy := _xy(chain, "clay_pit")
	if pit_xy != Vector2i.ZERO:
		_build(session, GameConstants.BUILDINGS["CLAY_PIT"], pit_xy, settlement, island)

	var yard_xy := _xy(chain, "brickyard")
	if yard_xy != Vector2i.ZERO:
		_build(session, GameConstants.BUILDINGS["BRICKYARD"], yard_xy, settlement, island)


static func _build(
	session: GameSession,
	building_id: int,
	at: Vector2i,
	settlement: Settlement,
	island: Island
) -> Building:
	var cmd := BuildCommand.new(building_id, at.x, at.y, island, settlement)
	cmd.skip_cost = true
	return cmd.execute(session) as Building


static func _build_ownerless_cmd(
	session: GameSession,
	building_id: int,
	at: Vector2i
) -> Building:
	var cmd := BuildCommand.new(building_id, at.x, at.y, session.island, null, true)
	cmd.skip_cost = true
	return cmd.execute(session) as Building


static func _xy(chain: Dictionary, key: String) -> Vector2i:
	var node: Variant = chain.get(key, {})
	if typeof(node) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(node.get("x", 0)), int(node.get("y", 0)))
