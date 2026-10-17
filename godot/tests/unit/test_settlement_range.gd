extends GutTest

## Subset of tests/game/test_settlement_range.py — placement outside warehouse radius fails.


func test_lumberjack_outside_settlement_range_fails() -> void:
	var gts := GameTestSession.start(true)
	# Far corner of test island, outside warehouse radius seed.
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 20, 20)
	assert_null(lj)
