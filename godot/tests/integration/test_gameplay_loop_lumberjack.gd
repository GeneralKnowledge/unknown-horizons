extends GutTest

## End-to-end sim loop: build lumberjack + trees → boards → snapshot round-trip.


func test_lumberjack_loop_with_snapshot_roundtrip() -> void:
	var gts := GameTestSession.start(true)
	var jack: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(jack)
	for x_off in [2, 4]:
		for y_off in [0, 2]:
			var tree: Building = gts.build(
				GameConstants.BUILDINGS["TREE"], 30 + x_off, 30 + y_off
			)
			assert_not_null(tree)
			tree.get_producer().finish_production_now()
	gts.run_seconds(30)
	var boards_before := jack.get_storage().amount(GameConstants.RES["BOARDS"])
	assert_true(boards_before > 0)

	var restored: GameSession = gts.snapshot_roundtrip()
	var jack2: Building = null
	for b in restored.get_buildings_on_island(restored.island):
		if b.building_id == GameConstants.BUILDINGS["LUMBERJACK"]:
			jack2 = b
			break
	assert_not_null(jack2)
	assert_eq(boards_before, jack2.get_storage().amount(GameConstants.RES["BOARDS"]))
