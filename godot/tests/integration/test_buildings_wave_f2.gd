extends GutTest

## Ports tests/game/test_buildings.py wave F2 (hunter, fisherman, tree wild-animal food).


func test_hunter() -> void:
	var gts := GameTestSession.start(true)
	var hunter: Building = gts.build(GameConstants.BUILDINGS["HUNTER"], 30, 30)
	assert_not_null(hunter)
	# No wild-animal units yet — feed inputs like simplified Python test setup.
	hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)
	gts.run_seconds(15)
	assert_true(hunter.get_storage().amount(GameConstants.RES["FOOD"]) > 0)


func test_fisherman() -> void:
	var gts := GameTestSession.start(true)
	for x in [33, 35, 37]:
		var school: Building = gts.build_ownerless(GameConstants.BUILDINGS["FISH_DEPOSIT"], x, 20)
		assert_not_null(school)
		school.get_producer().finish_production_now()
	var fisherman: Building = gts.build(GameConstants.BUILDINGS["FISHER"], 33, 23)
	assert_not_null(fisherman)
	assert_eq(0, fisherman.get_storage().amount(GameConstants.RES["FOOD"]))
	gts.run_seconds(25)
	assert_true(fisherman.get_storage().amount(GameConstants.RES["FOOD"]) > 0)


func test_tree_wildanimalfood_production() -> void:
	var gts := GameTestSession.start(true)
	var tree: Building = gts.build(GameConstants.BUILDINGS["TREE"], 30, 35)
	var inv := tree.get_storage()
	for _i in range(20):
		while inv.amount(GameConstants.RES["WILDANIMALFOOD"]) < 1:
			gts.run_seconds(5)
			if inv.amount(GameConstants.RES["WILDANIMALFOOD"]) < 1:
				tree.get_producer().finish_production_now()
		inv.alter(GameConstants.RES["WILDANIMALFOOD"], -1)
	assert_eq(0, inv.amount(GameConstants.RES["WILDANIMALFOOD"]))
