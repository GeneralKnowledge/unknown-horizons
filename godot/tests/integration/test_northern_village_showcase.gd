extends GutTest

const SCENARIO := "res://resources/demo/northern_village_showcase.json"


func test_showcase_boots_many_buildings_and_warmup() -> void:
	var scenario := DemoScenarioRunner.load_dict(SCENARIO)
	assert_false(scenario.is_empty())
	var session := DemoScenarioRunner.boot_from_dict(scenario, 8.0)
	assert_not_null(session)
	var count := session.get_buildings_on_island(session.island).size()
	assert_true(count >= 12, "expected living village footprint, got %d" % count)
	assert_true(session.settlement.inventory.amount(GameConstants.RES["BOARDS"]) >= 10)


func test_camera_spots_defined() -> void:
	var scenario := DemoScenarioRunner.load_dict(SCENARIO)
	var wide := DemoScenarioRunner.camera_spot(scenario, "wide")
	assert_true(wide.has("x"))
	assert_true(wide.has("zoom"))
