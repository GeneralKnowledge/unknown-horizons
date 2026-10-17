extends GutTest

## Ports tests/game/test_buildings.py wave F1 (build/tear, tree wood, lumberjack).


func test_build_tear() -> void:
	var gts := GameTestSession.start(true)
	var tree: Building = gts.build(GameConstants.BUILDINGS["TREE"], 30, 35)
	assert_not_null(tree)
	var wid: int = tree.worldid
	gts.run_ticks(1)
	assert_true(gts.tear(tree))
	assert_null(gts.session.registry.get_by_id(wid))


func test_tree_wood_production() -> void:
	var gts := GameTestSession.start(true)
	var tree: Building = gts.build(GameConstants.BUILDINGS["TREE"], 30, 35)
	var inv := tree.get_storage()
	for _i in range(20):
		while inv.amount(GameConstants.RES["TREES"]) < 1:
			gts.run_seconds(5)
			if inv.amount(GameConstants.RES["TREES"]) < 1:
				tree.get_producer().finish_production_now()
		inv.alter(GameConstants.RES["TREES"], -1)
	assert_eq(0, inv.amount(GameConstants.RES["TREES"]))


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
