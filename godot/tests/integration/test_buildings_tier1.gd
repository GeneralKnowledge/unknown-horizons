extends GutTest


func test_lumberjack() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island

	var jack: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 30, 30, island, settlement
	).execute(session) as Building
	assert_not_null(jack)
	assert_eq(0, jack.get_storage().amount(GameConstants.RES["BOARDS"]))

	for x_off in [2, 4]:
		for y_off in [0, 2]:
			var tree: Building = BuildCommand.new(
				GameConstants.BUILDINGS["TREE"],
				30 + x_off,
				30 + y_off,
				island,
				settlement
			).execute(session) as Building
			assert_not_null(tree)
			tree.get_producer().finish_production_now()

	session.run_seconds(30)
	assert_true(jack.get_storage().amount(GameConstants.RES["BOARDS"]) > 0)


func test_hunter() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island

	var hunter: Building = BuildCommand.new(
		GameConstants.BUILDINGS["HUNTER"], 30, 30, island, settlement
	).execute(session) as Building
	assert_not_null(hunter)
	hunter.get_storage().alter(GameConstants.RES["DEER_MEAT"], 2)
	session.run_seconds(15)
	assert_true(hunter.get_storage().amount(GameConstants.RES["FOOD"]) > 0)


func test_build_tear() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island

	var tree: Building = BuildCommand.new(
		GameConstants.BUILDINGS["TREE"], 30, 35, island, settlement
	).execute(session) as Building
	assert_not_null(tree)
	var wid: int = tree.worldid
	session.run_ticks(1)
	assert_true(bool(TearCommand.new(tree).execute(session)))
	assert_null(session.registry.get_by_id(wid))
