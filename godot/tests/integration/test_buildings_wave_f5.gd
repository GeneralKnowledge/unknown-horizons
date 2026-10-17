extends GutTest

## Ports tests/game/test_buildings.py wave F5 (Tier 3 / manual-input chains).


func test_school_production() -> void:
	var gts := GameTestSession.start(true)
	var school: Building = gts.build(GameConstants.BUILDINGS["VILLAGE_SCHOOL"], 30, 30)
	assert_not_null(school)
	assert_eq(0, school.get_storage().amount(GameConstants.RES["EDUCATION"]))
	gts.run_seconds(30)
	assert_true(school.get_storage().amount(GameConstants.RES["EDUCATION"]) > 0)


func test_distillery_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var distillery: Building = gts.build(GameConstants.BUILDINGS["DISTILLERY"], 30, 26)
	assert_not_null(distillery)
	distillery.get_storage().alter(GameConstants.RES["SUGAR"], 4)
	assert_eq(0, distillery.get_storage().amount(GameConstants.RES["LIQUOR"]))
	gts.run_seconds(30)
	assert_true(distillery.get_storage().amount(GameConstants.RES["LIQUOR"]) > 0)


func test_brewery_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var brewery: Building = gts.build(GameConstants.BUILDINGS["BREWERY"], 30, 26)
	assert_not_null(brewery)
	brewery.get_storage().alter(GameConstants.RES["HOPS"], 4)
	gts.run_seconds(30)
	assert_true(brewery.get_storage().amount(GameConstants.RES["BEER"]) > 0)


func test_tobbaconist_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var shop: Building = gts.build(GameConstants.BUILDINGS["TOBACCONIST"], 30, 26)
	assert_not_null(shop)
	shop.get_storage().alter(GameConstants.RES["TOBACCO_LEAVES"], 4)
	gts.run_seconds(45)
	assert_true(shop.get_storage().amount(GameConstants.RES["TOBACCO_PRODUCTS"]) > 0)


func test_blender_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var blender: Building = gts.build(GameConstants.BUILDINGS["BLENDER"], 30, 26)
	assert_not_null(blender)
	blender.get_storage().alter(GameConstants.RES["SPICES"], 4)
	gts.run_seconds(30)
	assert_true(blender.get_storage().amount(GameConstants.RES["CONDIMENTS"]) > 0)


func test_doctor_curing_chain() -> void:
	var gts := GameTestSession.start(true)
	var doctor: Building = gts.build(GameConstants.BUILDINGS["DOCTOR"], 30, 26)
	assert_not_null(doctor)
	doctor.get_storage().alter(GameConstants.RES["BLACKDEATH"], 1)
	doctor.get_storage().alter(GameConstants.RES["MEDICAL_HERBS"], 2)
	gts.run_seconds(90)
	assert_eq(0, doctor.get_storage().amount(GameConstants.RES["BLACKDEATH"]))


func test_winery_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var winery: Building = gts.build(GameConstants.BUILDINGS["WINERY"], 30, 26)
	assert_not_null(winery)
	winery.get_storage().alter(GameConstants.RES["GRAPES"], 4)
	gts.run_seconds(45)
	assert_true(winery.get_storage().amount(GameConstants.RES["LIQUOR"]) > 0)


func test_butchery_production_chain() -> void:
	var gts := GameTestSession.start(true)
	var butchery: Building = gts.build(GameConstants.BUILDINGS["BUTCHERY"], 30, 26)
	assert_not_null(butchery)
	butchery.get_storage().alter(GameConstants.RES["PIGS_SLAUGHTER"], 2)
	butchery.get_storage().alter(GameConstants.RES["CATTLE_SLAUGHTER"], 2)
	gts.run_seconds(45)
	assert_true(butchery.get_storage().amount(GameConstants.RES["FOOD"]) >= 4)
