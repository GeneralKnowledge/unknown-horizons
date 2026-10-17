extends GutTest

## Tier 1 economy — uses GameTestSession harness.


func test_lumberjack() -> void:
	var gts := GameTestSession.start(true)
	var jack: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(jack)
	assert_eq(0, jack.get_storage().amount(GameConstants.RES["BOARDS"]))
	for x_off in [2, 4]:
		for y_off in [0, 2]:
			var tree: Building = gts.build(
				GameConstants.BUILDINGS["TREE"], 30 + x_off, 30 + y_off
			)
			assert_not_null(tree)
			tree.get_producer().finish_production_now()
	gts.run_seconds(30)
	assert_true(jack.get_storage().amount(GameConstants.RES["BOARDS"]) > 0)


func test_hunter() -> void:
	var gts := GameTestSession.start(true)
	var hunter: Building = gts.build(GameConstants.BUILDINGS["HUNTER"], 30, 30)
	assert_not_null(hunter)
	hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)
	gts.run_seconds(15)
	assert_true(hunter.get_storage().amount(GameConstants.RES["FOOD"]) > 0)
