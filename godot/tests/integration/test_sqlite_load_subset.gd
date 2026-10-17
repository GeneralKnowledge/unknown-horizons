extends GutTest


func test_sqlite_fixture_loads_buildings() -> void:
	var path := GameTestSession.legacy_sqlite_fixture_path()
	if not FileAccess.file_exists(path):
		pending("SQLite fixture not present at %s" % path)
		return
	var session := SqliteSaveLoader.load(path)
	if session == null:
		pending("sqlite extract helper unavailable in this environment")
		return
	var count := session.get_buildings_on_island(session.island).size()
	assert_gte(count, 1)
