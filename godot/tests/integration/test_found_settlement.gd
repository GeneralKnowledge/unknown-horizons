extends GutTest

const FoundSettlementCommand = preload("res://scripts/sim/commands/found_settlement_command.gd")

## Legacy tests/gui/helper.found_settlement + test_build.test_found_settlement (sim path).


func test_trade_ship_founds_warehouse_on_unsettled_map() -> void:
	var gts := GameTestSession.start(false)
	var origin := TestMapFactory.default_settlement_point()
	var ship := gts.session.spawn_trade_ship(origin.x, origin.y - 2, gts.player.worldid)
	ship.inventory.alter(GameConstants.RES["GOLD"], 2000)
	ship.inventory.alter(GameConstants.RES["BOARDS"], 20)
	var warehouse: Building = gts.session.manager.execute(
		FoundSettlementCommand.new(ship, origin.x, origin.y)
	) as Building
	assert_not_null(warehouse)
	assert_eq(GameConstants.BUILDINGS["WAREHOUSE"], warehouse.building_id)
	assert_eq(1, gts.session.settlement.buildings.size())
	assert_true(gts.session.settlement.can_place_building(Vector2i(30, 30), Vector2i(3, 3)))


func test_found_settlement_requires_ship_near_site() -> void:
	var gts := GameTestSession.start(false)
	var origin := TestMapFactory.default_settlement_point()
	var ship := gts.session.spawn_trade_ship(10, 10, gts.player.worldid)
	ship.inventory.alter(GameConstants.RES["GOLD"], 5000)
	ship.inventory.alter(GameConstants.RES["BOARDS"], 50)
	var warehouse: Variant = gts.session.manager.execute(
		FoundSettlementCommand.new(ship, origin.x, origin.y)
	)
	assert_null(warehouse)


func test_cannot_found_twice() -> void:
	var gts := GameTestSession.start(false)
	var origin := TestMapFactory.default_settlement_point()
	var ship := gts.session.spawn_trade_ship(origin.x, origin.y, gts.player.worldid)
	ship.inventory.alter(GameConstants.RES["GOLD"], 5000)
	ship.inventory.alter(GameConstants.RES["BOARDS"], 50)
	assert_not_null(
		gts.session.manager.execute(FoundSettlementCommand.new(ship, origin.x, origin.y))
	)
	assert_null(
		gts.session.manager.execute(FoundSettlementCommand.new(ship, origin.x + 3, origin.y))
	)
