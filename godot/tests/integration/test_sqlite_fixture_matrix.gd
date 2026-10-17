extends GutTest


const FIXTURE_LIST := "res://resources/fixtures/sqlite_save_fixtures.json"


func test_each_listed_fixture_loads_without_null_session() -> void:
	if OS.has_feature("web"):
		pending("SQLite import is desktop-only")
		return
	if not FileAccess.file_exists(FIXTURE_LIST):
		pending("Run sqlite_fixture_matrix.py to generate fixture list")
		return
	var paths: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_LIST))
	if typeof(paths) != TYPE_ARRAY or paths.is_empty():
		pending("Empty fixture list")
		return
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var loaded := 0
	for rel in paths:
		var abs_path := repo_root.path_join(str(rel))
		if not FileAccess.file_exists(abs_path):
			continue
		var session := SqliteSaveLoader.load(abs_path)
		assert_not_null(session, "fixture load failed: %s" % rel)
		loaded += 1
	assert_gte(loaded, 1, "Expected at least one fixture to load")
