extends GutTest

const FIXTURES := {
	"fire": "legacy/tests/game/fixtures/fire.sqlite",
	"settlement-range": "legacy/tests/game/fixtures/settlement-range.sqlite",
	"traderoute": "legacy/tests/game/fixtures/traderoute.sqlite",
}


func _assert_session_tick_parity(fixture_name: String, rel_path: String) -> void:
	var path := M7SaveTestHelpers.repo_root().path_join(rel_path)
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var header := M7SaveTestHelpers.extract_session_dict(path)
	var expected_tick := int(header.get("estimated_cur_tick", -1))
	if expected_tick < 0:
		pending("%s: no session tick in extract" % fixture_name)
		return
	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	assert_eq(
		expected_tick,
		session.scheduler.cur_tick,
		"%s scheduler.cur_tick after load" % fixture_name
	)


func test_m7_fire_session_tick_matches_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_session_tick_parity("fire", FIXTURES["fire"])


func test_m7_settlement_range_session_tick_matches_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_session_tick_parity("settlement-range", FIXTURES["settlement-range"])


func test_m7_traderoute_session_tick_matches_extract() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	_assert_session_tick_parity("traderoute", FIXTURES["traderoute"])
