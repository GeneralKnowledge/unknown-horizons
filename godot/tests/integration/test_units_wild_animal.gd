extends GutTest


func test_wild_animal_produces_deer_meat() -> void:
	var gts := GameTestSession.start(true)
	var animal := gts.spawn_wild_animal(30, 30)
	assert_not_null(animal)
	animal.get_storage().alter(GameConstants.RES["WILDANIMALFOOD"], 2)
	animal.get_producer().finish_production_now()
	assert_true(animal.get_storage().amount(GameConstants.RES["DEER_MEAT"]) > 0)


func test_hunter_collects_from_wild_animal() -> void:
	var gts := GameTestSession.start(true)
	var hunter: Building = gts.build(GameConstants.BUILDINGS["HUNTER"], 30, 30)
	assert_not_null(hunter)
	var animal := gts.spawn_wild_animal(32, 32)
	animal.get_storage().alter(GameConstants.RES["WILDANIMALFOOD"], 4)
	animal.get_producer().finish_production_now()
	assert_true(animal.get_storage().amount(GameConstants.RES["DEER_MEAT"]) > 0)
	gts.run_seconds(30)
	var food := hunter.get_storage().amount(GameConstants.RES["FOOD"])
	var meat := hunter.get_storage().amount(GameConstants.RES["DEER_MEAT"])
	assert_true(food > 0 or meat > 0)
