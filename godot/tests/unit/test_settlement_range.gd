extends GutTest

## Subset of tests/game/test_settlement_range.py — settlement buildability via ground map.


func test_lumberjack_outside_settlement_range_fails() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 20, 20)
	assert_null(lj)


func test_non_buildable_upon_blocks_same_tile() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
	var lj2: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_null(lj2)


func test_buildable_upon_tree_allows_adjacent_placement() -> void:
	var gts := GameTestSession.start(true)
	var tree: Building = gts.build(GameConstants.BUILDINGS["TREE"], 32, 30)
	assert_not_null(tree)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(lj)
