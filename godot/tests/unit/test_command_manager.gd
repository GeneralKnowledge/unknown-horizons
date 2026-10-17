extends GutTest


func test_immediate_execute() -> void:
	var session := GameSession.new()
	session.load_test_map()
	var cmd := BuildCommand.new(
		GameConstants.BUILDINGS["TREE"],
		30,
		30,
		session.island,
		session.settlement,
		true
	)
	var building: Building = session.manager.execute(cmd) as Building
	assert_not_null(building)
	assert_eq(0, session.manager.pending_count())


func test_deferred_flush() -> void:
	var session := GameSession.new()
	session.load_test_map()
	session.manager.defer_to_tick_end = true
	var cmd := BuildCommand.new(
		GameConstants.BUILDINGS["TREE"],
		31,
		31,
		session.island,
		session.settlement,
		true
	)
	assert_null(session.manager.execute(cmd, false))
	assert_eq(1, session.manager.pending_count())
	var results := session.manager.flush()
	assert_eq(1, results.size())
	assert_not_null(results[0])
