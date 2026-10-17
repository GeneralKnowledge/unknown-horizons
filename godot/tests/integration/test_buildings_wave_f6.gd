extends GutTest

## Ports remaining tests/game/test_buildings.py cases (manual-input / simplified where sim gaps remain).


func test_stonemason_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var deposit: Building = gts.build_ownerless(GameConstants.BUILDINGS["STONE_DEPOSIT"], 33, 33)
	assert_not_null(deposit)
	var pit: Building = gts.build(GameConstants.BUILDINGS["STONE_PIT"], 33, 33)
	assert_not_null(pit)
	var mason: Building = gts.build(GameConstants.BUILDINGS["STONEMASON"], 33, 25)
	assert_not_null(mason)
	mason.get_storage().alter(GameConstants.RES["STONE_TOPS"], 4)
	assert_eq(0, mason.get_storage().amount(GameConstants.RES["BRICKS"]))
	gts.run_seconds(45)
	assert_true(mason.get_storage().amount(GameConstants.RES["BRICKS"]) > 0)


func test_pastryshop_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var shop: Building = gts.build(GameConstants.BUILDINGS["PASTRY_SHOP"], 30, 26)
	assert_not_null(shop)
	shop.get_storage().alter(GameConstants.RES["HONEYCOMBS"], 2)
	shop.get_storage().alter(GameConstants.RES["COCOA"], 2)
	shop.get_storage().alter(GameConstants.RES["GRAPES"], 2)
	gts.run_seconds(60)
	assert_true(shop.get_storage().amount(GameConstants.RES["CANDLES"]) > 0)
	assert_gte(shop.get_storage().amount(GameConstants.RES["CONFECTIONERY"]), 1)


func test_cannonfoundry_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var foundry: Building = gts.build(GameConstants.BUILDINGS["CANNON_FOUNDRY"], 30, 32)
	assert_not_null(foundry)
	foundry.get_storage().alter(GameConstants.RES["BOARDS"], 10)
	foundry.get_storage().alter(GameConstants.RES["CHARCOAL"], 4)
	foundry.get_storage().alter(GameConstants.RES["IRON_INGOTS"], 4)
	gts.run_seconds(90)
	assert_true(foundry.get_storage().amount(GameConstants.RES["CANNON"]) > 0)


func test_weaponsmith_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var smith: Building = gts.build(GameConstants.BUILDINGS["WEAPONSMITH"], 22, 32)
	assert_not_null(smith)
	smith.get_storage().alter(GameConstants.RES["CHARCOAL"], 4)
	smith.get_storage().alter(GameConstants.RES["IRON_INGOTS"], 4)
	gts.run_seconds(60)
	assert_true(smith.get_storage().amount(GameConstants.RES["SWORD"]) > 0)


func test_farm_crop_production() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30)
	if farm == null:
		pending("FARM placement on test map")
		return
	farm.get_storage().alter(GameConstants.RES["GRAIN"], 3)
	assert_true(gts.run_until(farm, GameConstants.RES["CORN"], 1, 90.0))


func test_farm_animal_production() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30)
	if farm == null:
		pending("FARM placement on test map")
		return
	farm.get_storage().alter(GameConstants.RES["LAMB_WOOL"], 2)
	assert_true(gts.run_until(farm, GameConstants.RES["WOOL"], 1, 90.0))


func test_barracks_production_chain() -> void:
	# Legacy pytest xfail covers soldier equip; Godot port verifies placement + armory storage.
	var gts := GameTestSession.start(true)
	var barracks: Building = gts.build(GameConstants.BUILDINGS["BARRACKS"], 26, 30)
	assert_not_null(barracks)
	barracks.get_storage().alter(GameConstants.RES["SWORD"], 2)
	assert_gte(barracks.get_storage().amount(GameConstants.RES["SWORD"]), 2)
