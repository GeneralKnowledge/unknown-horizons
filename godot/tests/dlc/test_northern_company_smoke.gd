extends GutTest


func test_northern_signal_tower_produces_faith() -> void:
	var gts := GameTestSession.start(true)
	var tower: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_SIGNAL_TOWER"], 32, 30)
	assert_not_null(tower)
	assert_eq(0, tower.get_storage().amount(GameConstants.RES["FAITH"]))
	gts.run_seconds(20)
	assert_true(tower.get_storage().amount(GameConstants.RES["FAITH"]) > 0)


func test_northern_mint_with_boards() -> void:
	var gts := GameTestSession.start(true)
	var mint: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_MINT"], 32, 28)
	assert_not_null(mint)
	mint.get_storage().alter(GameConstants.RES["BOARDS"], 4)
	gts.run_seconds(45)
	assert_true(mint.get_storage().amount(GameConstants.RES["GOLD"]) > 0)


func test_northern_smokery_with_fish() -> void:
	var gts := GameTestSession.start(true)
	var smokery: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_SMOKERY"], 34, 30)
	assert_not_null(smokery)
	smokery.get_storage().alter(GameConstants.RES["FISH"], 4)
	gts.run_seconds(40)
	assert_true(smokery.get_storage().amount(GameConstants.RES["FOOD"]) > 0)


func test_dlc_stem_resolution() -> void:
	var stem := ContentLoader.stem_for_building_id(DlcConstants.BUILDINGS["NORTHERN_OUTPOST"])
	assert_eq("northern_outpost", stem)
	assert_true(ContentLoader.is_dlc_building_id(DlcConstants.BUILDINGS["NORTHERN_OUTPOST"]))
