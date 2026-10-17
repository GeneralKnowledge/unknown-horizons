extends GutTest

const PRODUCTIONLINES_TREES := 256812226


func test_basic_wood_production() -> void:
	var settled := GameSession.settle()
	var session: GameSession = settled.session
	var settlement: Settlement = settled.settlement
	var island: Island = settled.island

	var lj: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"],
		30,
		30,
		island,
		settlement
	).execute(session) as Building
	assert_eq(GameConstants.BUILDINGS["LUMBERJACK"], lj.building_id)

	var storage: Inventory = lj.get_storage()
	var producer: Producer = lj.get_producer()
	assert_true(producer.has_production_line(PRODUCTIONLINES_TREES))
	var production: Production = producer._get_production(PRODUCTIONLINES_TREES)

	var production_finished := [false]
	production.add_production_finished_listener(func(_p): production_finished[0] = true)

	assert_true(producer.is_active())
	assert_eq(ProductionStates.WAITING_FOR_RES, producer._get_current_state())

	storage.alter(GameConstants.RES["TREES"], 2)
	assert_eq(ProductionStates.PRODUCING, producer._get_current_state())

	session.run_seconds(3)
	producer.toggle_active()
	assert_false(producer.is_active())
	assert_eq(ProductionStates.PAUSED, producer._get_current_state())

	producer.toggle_active()
	assert_true(producer.is_active())
	assert_eq(ProductionStates.PRODUCING, producer._get_current_state())

	session.run_seconds(2)
	assert_eq(ProductionStates.PRODUCING, producer._get_current_state())
	assert_eq(0, storage.amount(GameConstants.RES["BOARDS"]))
	assert_false(production_finished[0])

	session.run_seconds(10)
	assert_eq(ProductionStates.WAITING_FOR_RES, producer._get_current_state())
	assert_eq(1, storage.amount(GameConstants.RES["BOARDS"]))
	assert_true(production_finished[0])

	storage.alter(GameConstants.RES["BOARDS"], storage.get_limit(GameConstants.RES["BOARDS"]))
	assert_eq(ProductionStates.INVENTORY_FULL, producer._get_current_state())

	storage.alter(GameConstants.RES["BOARDS"], -storage.get_limit(GameConstants.RES["BOARDS"]))
	assert_eq(ProductionStates.WAITING_FOR_RES, producer._get_current_state())
