extends GutTest

## M7 criterion #4: post-load tick stepping — inventory totals match committed golden (fire).

const FIRE_FIXTURE := "legacy/tests/game/fixtures/fire.sqlite"
const TICKS := 128
const GOLDEN_PATH := "res://resources/fixtures/sqlite_m7/fire_tick128_inventory_totals.json"


func _repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


func _inventory_totals(session: GameSession) -> Dictionary:
	var totals: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		var inv: Inventory = building.get_storage()
		if inv == null:
			continue
		for res_id in inv.get_stored_resources().keys():
			var amount := int(inv.amount(int(res_id)))
			if amount == 0:
				continue
			totals[str(int(res_id))] = int(totals.get(str(int(res_id)), 0)) + amount
	for res_id in session.settlement.inventory.get_stored_resources().keys():
		var amount := session.settlement.inventory.amount(int(res_id))
		if amount == 0:
			continue
		totals[str(int(res_id))] = int(totals.get(str(int(res_id)), 0)) + amount
	return totals


func test_fire_fixture_tick128_inventory_totals_match_golden() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var path := _repo_root().path_join(FIRE_FIXTURE)
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return

	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	var tick_before := session.scheduler.cur_tick
	session.run_ticks(TICKS)
	assert_eq(tick_before + TICKS, session.scheduler.cur_tick)
	var actual := _inventory_totals(session)

	if OS.get_environment("WRITE_M7_GOLDEN") == "1":
		var payload := {
			"fixture": "fire.sqlite",
			"ticks": TICKS,
			"scheduler_tick": session.scheduler.cur_tick,
			"totals_by_resource_id": actual,
		}
		var out := ProjectSettings.globalize_path(GOLDEN_PATH)
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		var f := FileAccess.open(out, FileAccess.WRITE)
		assert_not_null(f)
		f.store_string(JSON.stringify(payload, "\t") + "\n")
		f.close()
		pass_test("wrote %s" % out)
		return

	if not FileAccess.file_exists(GOLDEN_PATH):
		fail_test("missing golden %s — run with WRITE_M7_GOLDEN=1" % GOLDEN_PATH)
		return
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	assert_eq(typeof(golden), TYPE_DICTIONARY)
	var expected: Dictionary = golden.get("totals_by_resource_id", {})
	assert_false(expected.is_empty())

	for res_key in expected.keys():
		assert_eq(
			int(expected[res_key]),
			int(actual.get(str(res_key), 0)),
			"fire tick %s res %s" % [TICKS, res_key]
		)
	for res_key in actual.keys():
		if int(actual[res_key]) == 0:
			continue
		assert_true(
			expected.has(res_key),
			"unexpected fire tick128 res %s = %s" % [res_key, actual[res_key]]
		)
