extends GutTest

const SCENARIO_PATH := "res://resources/demo/starter_tier1_scenario.json"


func _load_scenario() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	assert_eq(typeof(data), TYPE_DICTIONARY)
	return data


func test_tier1_hunter_fisher_and_warehouse_collector() -> void:
	var scenario := _load_scenario()
	var chain: Dictionary = scenario.get("chain", {})
	var gts := GameTestSession.start(true)

	var lumberjack: Building = gts.build(
		GameConstants.BUILDINGS["LUMBERJACK"],
		_xy(chain, "lumberjack").x,
		_xy(chain, "lumberjack").y
	)
	assert_not_null(lumberjack)

	var hunter: Building = gts.build(
		GameConstants.BUILDINGS["HUNTER"],
		_xy(chain, "hunter").x,
		_xy(chain, "hunter").y
	)
	assert_not_null(hunter)
	hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)
	gts.run_seconds(15)
	assert_true(hunter.get_storage().amount(GameConstants.RES["FOOD"]) > 0)

	for deposit: Dictionary in chain.get("fish_deposits", []):
		var school: Building = gts.build_ownerless(
			GameConstants.BUILDINGS["FISH_DEPOSIT"],
			int(deposit.get("x", 0)),
			int(deposit.get("y", 0))
		)
		assert_not_null(school)
		school.get_producer().finish_production_now()

	var fisher_xy := _xy(chain, "fisher")
	var fisher: Building = gts.build(
		GameConstants.BUILDINGS["FISHER"], fisher_xy.x, fisher_xy.y
	)
	assert_not_null(fisher)
	gts.run_seconds(25)
	assert_true(fisher.get_storage().amount(GameConstants.RES["FOOD"]) > 0)

	var cap: int = lumberjack.get_storage().get_limit(GameConstants.RES["BOARDS"])
	lumberjack.get_storage().alter(GameConstants.RES["BOARDS"], mini(10, cap))
	var settle_inv := gts.session.settlement.inventory
	var before: int = settle_inv.amount(GameConstants.RES["BOARDS"])
	gts.run_seconds(90)
	var moved: int = mini(10, cap) - lumberjack.get_storage().amount(GameConstants.RES["BOARDS"])
	assert_true(moved >= 4)
	assert_true(settle_inv.amount(GameConstants.RES["BOARDS"]) >= before + moved)


func _xy(chain: Dictionary, key: String) -> Vector2i:
	var node: Dictionary = chain.get(key, {})
	return Vector2i(int(node.get("x", 0)), int(node.get("y", 0)))
