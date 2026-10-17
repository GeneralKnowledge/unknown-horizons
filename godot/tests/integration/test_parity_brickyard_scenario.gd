extends GutTest

const SCENARIO := "res://resources/parity/brickyard.json"


func test_brickyard_parity_scenario_produces_bricks() -> void:
	if not FileAccess.file_exists(SCENARIO):
		pending("Copy parity scenarios via sync.sh or CI export step")
		return
	var runner := ScenarioRunner.new()
	var trace: Dictionary = runner.run_file(SCENARIO)
	assert_true(trace.has("buildings"))
	var found := false
	for row in trace.get("buildings", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str(row.get("stem", "")) != "brickyard":
			continue
		if int(row.get("x", -1)) != 33 or int(row.get("y", -1)) != 25:
			continue
		var storage: Dictionary = row.get("storage", {})
		if int(storage.get("BRICKS", 0)) >= 1:
			found = true
			break
	assert_true(found, "brickyard should have BRICKS in parity trace")
