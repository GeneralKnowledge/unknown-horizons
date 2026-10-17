class_name GameTestSession
extends RefCounted

var session: GameSession
var player: SimPlayer


static func start(settled: bool = true) -> GameTestSession:
	var wrap := GameTestSession.new()
	wrap.session = GameSession.new()
	wrap.session.load_test_map()
	if settled:
		GameTestHelpers.settle(wrap.session)
	wrap.player = SimPlayer.new(wrap.session.allocate_worldid(), wrap.session.settlement)
	return wrap


func run_ticks(ticks: int = 1) -> void:
	session.run_ticks(ticks)


func run_seconds(seconds: float) -> void:
	session.run_seconds(seconds)


func build(building_id: int, x: int, y: int) -> Building:
	return session.manager.execute(
		BuildCommand.new(building_id, x, y, session.island, session.settlement)
	) as Building


func tear(building: Building) -> bool:
	return bool(session.manager.execute(TearCommand.new(building)))
