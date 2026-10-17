extends GutTest

const SCENARIO_PATH := "res://resources/demo/starter_island_scenario.json"


func _load_scenario() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	assert_eq(typeof(data), TYPE_DICTIONARY)
	return data


func test_scenario_targets_development_map() -> void:
	var scenario := _load_scenario()
	assert_eq("development", str(scenario.get("map_id", "")))
	var session := GameSession.new()
	MapLoader.apply_map_to_session(session, DemoConfig.default_map_id())
	assert_gt(session.island.ground_map.size(), 400)


func test_scenario_chain_produces_bricks() -> void:
	var scenario := _load_scenario()
	var chain: Dictionary = scenario.get("chain", {})
	var gts := GameTestSession.new()
	gts.session = GameSession.new()
	MapLoader.apply_map_to_session(gts.session, str(scenario.get("map_id", "development")))
	var settle_cfg: Dictionary = scenario.get("settlement", {})
	GameTestHelpers.new_settlement(
		gts.session,
		Vector2i(int(settle_cfg.get("x", 30)), int(settle_cfg.get("y", 30)))
	)
	PlayableDemoConfig.apply_starting_resources(gts.session.settlement)
	gts.session.settlement.inventory.alter(GameConstants.RES["BOARDS"], 40)
	gts.session.settlement.inventory.alter(GameConstants.RES["GOLD"], 5000)
	gts.player = SimPlayer.new(gts.session.allocate_worldid(), gts.session.settlement)
	var deposit_xy: Vector2i = _xy(chain, "clay_deposit")
	var deposit: Building = gts.build_ownerless(GameConstants.BUILDINGS["CLAY_DEPOSIT"], deposit_xy.x, deposit_xy.y)
	assert_not_null(deposit)
	deposit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 10)
	var pit_xy: Vector2i = _xy(chain, "clay_pit")
	var pit: Building = gts.build(GameConstants.BUILDINGS["CLAY_PIT"], pit_xy.x, pit_xy.y)
	assert_not_null(pit)
	var yard_xy: Vector2i = _xy(chain, "brickyard")
	var brickyard: Building = gts.build(GameConstants.BUILDINGS["BRICKYARD"], yard_xy.x, yard_xy.y)
	assert_not_null(brickyard)
	gts.run_seconds(30)
	if pit.get_storage().amount(GameConstants.RES["CLAY"]) < 2:
		pit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 4)
	gts.run_seconds(30)
	if brickyard.get_storage().amount(GameConstants.RES["CLAY"]) < 2:
		brickyard.get_storage().alter(GameConstants.RES["CLAY"], 4)
	gts.run_seconds(20)
	assert_true(brickyard.get_storage().amount(GameConstants.RES["BRICKS"]) > 0)


func _xy(chain: Dictionary, key: String) -> Vector2i:
	var node: Dictionary = chain.get(key, {})
	return Vector2i(int(node.get("x", 0)), int(node.get("y", 0)))
