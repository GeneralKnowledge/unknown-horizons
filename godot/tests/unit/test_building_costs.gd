extends GutTest


func test_lumberjack_costs_deduct_from_settlement() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island
	var gold_before := settlement.inventory.amount(GameConstants.RES["GOLD"])
	var lj: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session) as Building
	assert_not_null(lj)
	assert_true(settlement.inventory.amount(GameConstants.RES["GOLD"]) < gold_before)


func test_insufficient_gold_blocks_build() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island
	settlement.inventory.reset(GameConstants.RES["GOLD"])
	settlement.inventory.alter(GameConstants.RES["GOLD"], 1)
	var lj: Variant = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session)
	assert_null(lj)


func test_founding_warehouse_skips_cost() -> void:
	var session := GameSession.new()
	session.load_test_map()
	session.settlement.inventory.reset(GameConstants.RES["GOLD"])
	var wh: Building = BuildCommand.new(
		GameConstants.BUILDINGS["WAREHOUSE"], 30, 30, session.island, session.settlement
	).execute(session) as Building
	assert_not_null(wh)
