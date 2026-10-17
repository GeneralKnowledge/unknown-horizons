extends GutTest


func test_blackdeath_loads_wild_animals_and_buildings() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var path := repo.path_join("legacy/tests/game/fixtures/blackdeath.sqlite")
	if not FileAccess.file_exists(path):
		pending("missing fixture")
		return
	var session := SqliteSaveLoader.load(path)
	assert_not_null(session)
	assert_gte(session.get_buildings_on_island(session.island).size(), 1)
	assert_gte(session.get_wild_animals_on_island(session.island).size(), 1)
	assert_gte(session.scheduler.cur_tick, 0)
