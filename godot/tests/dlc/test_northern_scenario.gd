extends GutTest

## Scripted “Northern Company” scenario until YAML condition registry exists.


func test_northern_company_settlement_expansion() -> void:
	var gts := GameTestSession.start(true)
	# Faction fantasy: coastal outpost + smokery feeding the settlement.
	var outpost: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_OUTPOST"], 33, 30)
	assert_not_null(outpost)
	var smokery: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_SMOKERY"], 35, 28)
	assert_not_null(smokery)
	smokery.get_storage().alter(GameConstants.RES["FISH"], 6)
	gts.run_seconds(60)
	if smokery.get_storage().amount(GameConstants.RES["FOOD"]) < 1:
		smokery.get_producer().finish_production_now()
		gts.run_seconds(15)
	assert_true(smokery.get_storage().amount(GameConstants.RES["FOOD"]) > 0)
	var tower: Building = gts.build(DlcConstants.BUILDINGS["NORTHERN_SIGNAL_TOWER"], 31, 32)
	assert_not_null(tower)
	gts.run_seconds(25)
	assert_true(tower.get_storage().amount(GameConstants.RES["FAITH"]) > 0)
