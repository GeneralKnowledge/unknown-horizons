extends GutTest


func test_warehouse_pulls_boards_from_lumberjack() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	var cap: int = lj.get_storage().get_limit(GameConstants.RES["BOARDS"])
	assert_true(cap > 0)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], cap)
	var settle_inv := gts.session.settlement.inventory
	var before: int = settle_inv.amount(GameConstants.RES["BOARDS"])
	gts.run_seconds(90)
	var moved: int = cap - lj.get_storage().amount(GameConstants.RES["BOARDS"])
	assert_true(moved >= 4)
	assert_true(settle_inv.amount(GameConstants.RES["BOARDS"]) >= before + moved)
