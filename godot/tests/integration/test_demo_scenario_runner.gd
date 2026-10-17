extends GutTest

const SCENARIO := "res://resources/demo/starter_tier1_scenario.json"


func test_boot_tier1_places_core_buildings() -> void:
	var session := DemoScenarioRunner.boot_from_resource(SCENARIO, 0.0)
	assert_not_null(session)
	var island := session.island
	var lj := 0
	var hunter := 0
	var fisher := 0
	for b in session.get_buildings_on_island(island):
		match b.building_id:
			GameConstants.BUILDINGS["LUMBERJACK"]:
				lj += 1
			GameConstants.BUILDINGS["HUNTER"]:
				hunter += 1
			GameConstants.BUILDINGS["FISHER"]:
				fisher += 1
	assert_eq(lj, 1)
	assert_eq(hunter, 1)
	assert_eq(fisher, 1)
