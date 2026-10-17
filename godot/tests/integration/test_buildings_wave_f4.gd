extends GutTest

## Ports tests/game/test_buildings.py wave F4 (simplified chains with manual inputs).


func test_pavilion_production() -> void:
	var gts := GameTestSession.start(true)
	var pavilion: Building = gts.build(GameConstants.BUILDINGS["PAVILION"], 30, 30)
	assert_not_null(pavilion)
	assert_eq(0, pavilion.get_storage().amount(GameConstants.RES["FAITH"]))
	gts.run_seconds(30)
	assert_true(pavilion.get_storage().amount(GameConstants.RES["FAITH"]) > 0)


func test_saltpond_production() -> void:
	var gts := GameTestSession.start(true)
	var pond: Building = gts.build(GameConstants.BUILDINGS["SALT_PONDS"], 33, 22)
	assert_not_null(pond)
	assert_eq(0, pond.get_storage().amount(GameConstants.RES["SALT"]))
	gts.run_seconds(60)
	assert_true(pond.get_storage().amount(GameConstants.RES["SALT"]) >= 2)


func test_bakery_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var bakery: Building = gts.build(GameConstants.BUILDINGS["BAKERY"], 30, 26)
	assert_not_null(bakery)
	bakery.get_storage().alter(GameConstants.RES["FLOUR"], 4)
	assert_eq(0, bakery.get_storage().amount(GameConstants.RES["FOOD"]))
	gts.run_seconds(45)
	assert_true(bakery.get_storage().amount(GameConstants.RES["FOOD"]) > 0)


func test_weaver_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var weaver: Building = gts.build(GameConstants.BUILDINGS["WEAVER"], 30, 26)
	assert_not_null(weaver)
	weaver.get_storage().alter(GameConstants.RES["WOOL"], 4)
	assert_eq(0, weaver.get_storage().amount(GameConstants.RES["TEXTILE"]))
	gts.run_seconds(45)
	assert_true(weaver.get_storage().amount(GameConstants.RES["TEXTILE"]) > 0)
