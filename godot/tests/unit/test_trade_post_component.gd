extends GutTest


func test_buy_and_sell_slots() -> void:
	var session := GameSession.new()
	session.load_test_map()
	var owner := PositiveSizedSpecializedInventory.new({GameConstants.RES["GOLD"]: 999})
	var building_inv := PositiveSizedSpecializedInventory.new({1: 10})
	var b := Building.new(1, 1, Vector2i(0, 0), session.island, null, building_inv, null)
	var tp := TradePostComponent.new(b, owner)
	owner.alter(GameConstants.RES["GOLD"], 1)
	assert_false(tp.buy(1, 1, 1, 100))
	tp.set_slot(0, 1, false, 2)
	assert_true(tp.buy(1, 1, 1, 100))
	assert_eq(1, tp.buy_expenses)
	owner.alter(GameConstants.RES["GOLD"], 2)
	assert_true(tp.buy(1, 1, 1, 100))
	tp.clear_slot(0, true)
	assert_false(tp.buy(1, 1, 1, 100))
	assert_eq(2, tp.total_expenses)


func test_sell() -> void:
	var session := GameSession.new()
	var owner := PositiveSizedSpecializedInventory.new({GameConstants.RES["GOLD"]: 0})
	var building_inv := PositiveSizedSpecializedInventory.new({1: 10})
	var b := Building.new(1, 1, Vector2i(0, 0), session.island, null, building_inv, null)
	var tp := TradePostComponent.new(b, owner)
	building_inv.alter(1, 1)
	assert_false(tp.sell(1, 1, 1, 100))
	tp.set_slot(0, 1, true, 0)
	assert_true(tp.sell(1, 1, 1, 100))
	assert_eq(1, tp.sell_income)
	assert_false(tp.sell(1, 1, 1, 100))
	building_inv.alter(1, 1)
	assert_true(tp.sell(1, 1, 1, 100))
	tp.clear_slot(0, true)
	assert_false(tp.sell(1, 1, 1, 100))
	assert_eq(2, tp.total_earnings)
