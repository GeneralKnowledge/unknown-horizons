extends GutTest

## M7: compare Godot vs legacy Python inventory totals after ticks (when FIFE available).
## CI uses T1l Godot tick goldens; this test is optional local/FIFE validation only.

const FIRE_FIXTURE := "legacy/tests/game/fixtures/fire.sqlite"
const TICKS := 128
const PROBE_SCRIPT := "development/godot/sqlite_m7_legacy_fire_ticks.py"


func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


func _godot_totals_after_ticks(sqlite_path: String) -> Dictionary:
	var session := SqliteSaveLoader.load(sqlite_path)
	assert_not_null(session)
	session.run_ticks(TICKS)
	var totals: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		var inv: Inventory = building.get_storage()
		if inv == null:
			continue
		for res_id in inv.get_stored_resources().keys():
			var amount := int(inv.amount(int(res_id)))
			if amount == 0:
				continue
			var key := str(int(res_id))
			totals[key] = int(totals.get(key, 0)) + amount
	for res_id in session.settlement.inventory.get_stored_resources().keys():
		var amount := session.settlement.inventory.amount(int(res_id))
		if amount == 0:
			continue
		var key := str(int(res_id))
		totals[key] = int(totals.get(key, 0)) + amount
	return totals


func test_fire_tick128_godot_inventory_matches_legacy_python_when_available() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var sqlite_path := _repo_root().path_join(FIRE_FIXTURE)
	if not FileAccess.file_exists(sqlite_path):
		pending("missing fixture")
		return
	var script := _repo_root().path_join(PROBE_SCRIPT)
	var tmp := "user://legacy_fire_tick128.json"
	var tmp_abs := ProjectSettings.globalize_path(tmp)
	var output: Array = []
	var code := OS.execute(
		"python3",
		[script, sqlite_path, tmp_abs, "--ticks", str(TICKS)],
		output,
		true
	)
	if code == 2:
		pending("legacy Python runtime (FIFE) not installed — dual-run skipped")
		return
	assert_eq(0, code, "legacy probe failed: %s" % str(output))
	var legacy: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	assert_eq(typeof(legacy), TYPE_DICTIONARY)
	var expected: Dictionary = legacy.get("totals_by_resource_id", {})
	var actual := _godot_totals_after_ticks(sqlite_path)
	for res_key in expected.keys():
		assert_eq(
			int(expected[res_key]),
			int(actual.get(str(res_key), 0)),
			"legacy vs godot tick %s res %s" % [TICKS, res_key]
		)
