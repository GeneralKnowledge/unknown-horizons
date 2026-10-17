extends GutTest


func _run(id: String) -> Dictionary:
	var path := "res://resources/parity/%s.json" % id
	if not FileAccess.file_exists(path):
		pending("Missing %s (run sync or CI copy)" % path)
		return {}
	var runner := ScenarioRunner.new()
	return runner.run_file(path)


func test_toolmaker_trace_has_tools() -> void:
	var trace := _run("toolmaker")
	assert_true(_building_has_min(trace, "toolmaker", 30, 32, "TOOLS", 1))


func test_brickyard_development_trace() -> void:
	var trace := _run("brickyard_development")
	assert_true(_building_has_min(trace, "brickyard", 33, 25, "BRICKS", 1))


func test_snapshot_mid_production_boards() -> void:
	var trace := _run("snapshot_mid_production")
	assert_true(_building_has_min(trace, "lumberjackcamp", 30, 30, "BOARDS", 1))


func _building_has_min(
	trace: Dictionary, stem: String, x: int, y: int, res: String, min_amt: int
) -> bool:
	for row in trace.get("buildings", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str(row.get("stem", "")) != stem:
			continue
		if int(row.get("x", -1)) != x or int(row.get("y", -1)) != y:
			continue
		var storage: Dictionary = row.get("storage", {})
		if int(storage.get(res, 0)) >= min_amt:
			return true
	return false
