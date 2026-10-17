extends GutTest


func test_transfer_boards_to_settlement() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	lj.get_storage().alter(GameConstants.RES["BOARDS"], 8)
	var before := gts.session.settlement.inventory.amount(GameConstants.RES["BOARDS"])
	var moved: int = gts.session.manager.execute(
		TransferToSettlementCommand.new(lj, GameConstants.RES["BOARDS"], 5)
	)
	assert_eq(5, moved)
	assert_eq(3, lj.get_storage().amount(GameConstants.RES["BOARDS"]))
	assert_eq(before + 5, gts.session.settlement.inventory.amount(GameConstants.RES["BOARDS"]))
