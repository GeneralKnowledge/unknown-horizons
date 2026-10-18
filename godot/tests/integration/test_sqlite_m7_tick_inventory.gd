extends GutTest

## M7 criterion #4: post-load tick stepping — inventory totals match committed goldens.

const TICKS := 128

const M7_TICK_FIXTURES := {
	"fire": {
		"rel": "legacy/tests/game/fixtures/fire.sqlite",
		"golden": "res://resources/fixtures/sqlite_m7/fire_tick128_inventory_totals.json",
	},
	"settlement-range": {
		"rel": "legacy/tests/game/fixtures/settlement-range.sqlite",
		"golden": "res://resources/fixtures/sqlite_m7/settlement_range_tick128_inventory_totals.json",
	},
	"traderoute": {
		"rel": "legacy/tests/game/fixtures/traderoute.sqlite",
		"golden": "res://resources/fixtures/sqlite_m7/traderoute_tick128_inventory_totals.json",
	},
}


func _inventory_totals_string_keys(session: GameSession) -> Dictionary:
	var raw := M7SaveTestHelpers.godot_inventory_totals(session)
	var out: Dictionary = {}
	for res_id in raw.keys():
		out[str(int(res_id))] = int(raw[res_id])
	return out


func _assert_tick_golden(fixture_key: String) -> void:
	var cfg: Dictionary = M7_TICK_FIXTURES[fixture_key]
	var path := M7SaveTestHelpers.repo_root().path_join(str(cfg["rel"]))
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var golden_path: String = str(cfg["golden"])

	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	var tick_before := session.scheduler.cur_tick
	session.run_ticks(TICKS)
	assert_eq(tick_before + TICKS, session.scheduler.cur_tick)
	var actual := _inventory_totals_string_keys(session)

	if OS.get_environment("WRITE_M7_GOLDEN") == "1":
		var payload := {
			"fixture": path.get_file(),
			"ticks": TICKS,
			"scheduler_tick": session.scheduler.cur_tick,
			"totals_by_resource_id": actual,
		}
		var out := ProjectSettings.globalize_path(golden_path)
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		var f := FileAccess.open(out, FileAccess.WRITE)
		assert_not_null(f)
		f.store_string(JSON.stringify(payload, "\t") + "\n")
		f.close()
		pass_test("wrote %s" % out)
		return

	if not FileAccess.file_exists(golden_path):
		fail_test("missing golden %s — run with WRITE_M7_GOLDEN=1" % golden_path)
		return
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(golden_path))
	assert_eq(typeof(golden), TYPE_DICTIONARY)
	var expected: Dictionary = golden.get("totals_by_resource_id", {})
	assert_false(expected.is_empty())

	for res_key in expected.keys():
		assert_eq(
			int(expected[res_key]),
			int(actual.get(str(res_key), 0)),
			"%s tick %s res %s" % [fixture_key, TICKS, res_key]
		)
	for res_key in actual.keys():
		if int(actual[res_key]) == 0:
			continue
		assert_true(
			expected.has(res_key),
			"%s unexpected tick128 res %s = %s" % [fixture_key, res_key, actual[res_key]]
		)


func test_m7_fire_tick128_inventory_totals_match_golden() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_tick_golden("fire")


func test_m7_settlement_range_tick128_inventory_totals_match_golden() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_tick_golden("settlement-range")


func test_m7_traderoute_tick128_inventory_totals_match_golden() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_tick_golden("traderoute")
