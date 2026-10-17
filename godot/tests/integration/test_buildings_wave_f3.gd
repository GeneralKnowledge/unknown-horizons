extends GutTest

## Ports tests/game/test_buildings.py wave F3 (production chains).


func test_brick_production_chain() -> void:
	var gts := GameTestSession.start(true)
	# Avoid warehouse footprint at default settle point (28, 28); Python uses (30, 20).
	var deposit: Building = gts.build_ownerless(GameConstants.BUILDINGS["CLAY_DEPOSIT"], 33, 33)
	assert_not_null(deposit)
	deposit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 10)
	var pit: Building = gts.build(GameConstants.BUILDINGS["CLAY_PIT"], 33, 33)
	assert_not_null(pit)
	var brickyard: Building = gts.build(GameConstants.BUILDINGS["BRICKYARD"], 33, 25)
	assert_not_null(brickyard)
	assert_eq(0, brickyard.get_storage().amount(GameConstants.RES["BRICKS"]))
	gts.run_seconds(30)
	if pit.get_storage().amount(GameConstants.RES["CLAY"]) < 2:
		pit.get_storage().alter(GameConstants.RES["RAW_CLAY"], 4)
	gts.run_seconds(30)
	if brickyard.get_storage().amount(GameConstants.RES["CLAY"]) < 2:
		brickyard.get_storage().alter(GameConstants.RES["CLAY"], 4)
	gts.run_seconds(20)
	assert_true(brickyard.get_storage().amount(GameConstants.RES["BRICKS"]) > 0)


func test_tool_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var toolmaker: Building = gts.build(GameConstants.BUILDINGS["TOOLMAKER"], 30, 32)
	assert_not_null(toolmaker)
	toolmaker.get_storage().alter(GameConstants.RES["BOARDS"], 10)
	toolmaker.get_storage().alter(GameConstants.RES["CHARCOAL"], 10)
	toolmaker.get_storage().alter(GameConstants.RES["IRON_INGOTS"], 4)
	assert_eq(0, toolmaker.get_storage().amount(GameConstants.RES["TOOLS"]))
	gts.run_seconds(180)
	if toolmaker.get_storage().amount(GameConstants.RES["TOOLS"]) < 1:
		toolmaker.get_producer().finish_production_now()
		gts.run_seconds(30)
	assert_true(toolmaker.get_storage().amount(GameConstants.RES["TOOLS"]) > 0)
