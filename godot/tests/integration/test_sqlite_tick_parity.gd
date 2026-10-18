extends GutTest

## P1: post-load sim stepping — legacy SQLite load then ticks without crash or inventory corruption.

const FIRE_LUMBERJACK_WORLDID := 1019
const FIRE_TICKS := 128


func _fire_fixture_path() -> String:
	return (
		ProjectSettings.globalize_path("res://").path_join("..")
		.path_join("legacy/tests/game/fixtures/fire.sqlite")
		.simplify_path()
	)


func test_fire_fixture_production_advances_inventories_after_ticks() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _fire_fixture_path()
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return

	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	var lumberjack := session.get_building(FIRE_LUMBERJACK_WORLDID)
	assert_not_null(lumberjack)
	assert_not_null(lumberjack.producer)

	var trees_before := lumberjack.get_storage().amount(GameConstants.RES["TREES"])
	var boards_before := lumberjack.get_storage().amount(GameConstants.RES["BOARDS"])
	var cannon_before := session.settlement.inventory.amount(GameConstants.RES["CANNON"])
	var building_count := session.get_buildings_on_island(session.island).size()
	var tick_before := session.scheduler.cur_tick

	session.run_ticks(FIRE_TICKS)

	assert_eq(tick_before + FIRE_TICKS, session.scheduler.cur_tick)
	assert_eq(building_count, session.get_buildings_on_island(session.island).size())
	assert_eq(cannon_before, session.settlement.inventory.amount(GameConstants.RES["CANNON"]))

	var trees_after := lumberjack.get_storage().amount(GameConstants.RES["TREES"])
	var boards_after := lumberjack.get_storage().amount(GameConstants.RES["BOARDS"])
	assert_true(
		boards_after != boards_before or trees_after != trees_before,
		"lumberjack storage should change after %s ticks (boards %s→%s, trees %s→%s)"
		% [FIRE_TICKS, boards_before, boards_after, trees_before, trees_after]
	)
