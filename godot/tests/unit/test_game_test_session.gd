extends GutTest


func test_harness_settles_and_builds() -> void:
	var gts := GameTestSession.start(true)
	assert_not_null(gts.session.manager)
	var lj := gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	assert_true(gts.session.settlement.buildings.size() >= 2)
