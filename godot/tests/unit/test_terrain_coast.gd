extends GutTest


func test_fisher_inland_fails_coast_requirement() -> void:
	var gts := GameTestSession.start(true)
	var inland: Building = gts.build(GameConstants.BUILDINGS["FISHER"], 33, 23)
	assert_null(inland)


func test_fisher_on_shore_succeeds() -> void:
	var gts := GameTestSession.start(true)
	for x in [35, 37]:
		assert_not_null(gts.build_ownerless(GameConstants.BUILDINGS["FISH_DEPOSIT"], x, 20))
	var fisherman: Building = gts.build(GameConstants.BUILDINGS["FISHER"], 33, 21)
	assert_not_null(fisherman)
