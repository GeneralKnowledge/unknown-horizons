class_name GameTestSession
extends RefCounted

var session: GameSession
var player: SimPlayer

const REPO_SQLITE_FIXTURE := "../legacy/tests/game/fixtures/savegame-rev-76.sqlite"


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


func build(building_id: int, x: int, y: int, auto_place_farm_fields: bool = true) -> Building:
	var cmd := BuildCommand.new(building_id, x, y, session.island, session.settlement)
	cmd.auto_place_farm_fields = auto_place_farm_fields
	return session.manager.execute(cmd) as Building


func build_ownerless(building_id: int, x: int, y: int) -> Building:
	return session.manager.execute(
		BuildCommand.new(building_id, x, y, session.island, null, true)
	) as Building


func build_farm(x: int, y: int, field_ids: Array = []) -> Building:
	return GameTestHelpers.build_farm(self, x, y, field_ids)


func tear(building: Building) -> bool:
	return bool(session.manager.execute(TearCommand.new(building)))


func spawn_wild_animal(x: int, y: int) -> WildAnimal:
	return spawn_unit("deer", x, y) as WildAnimal


func spawn_unit(unit_stem: String, x: int, y: int) -> Variant:
	return session.spawn_unit(session.island, unit_stem, x, y)


func run_until(
	building: Building,
	res_id: int,
	min_amount: int,
	max_seconds: float = 120.0
) -> bool:
	var step := 1.0
	var elapsed := 0.0
	while building.get_storage().amount(res_id) < min_amount and elapsed < max_seconds:
		run_seconds(step)
		elapsed += step
	if building.get_storage().amount(res_id) < min_amount:
		var producer := building.get_producer()
		if producer != null:
			producer.finish_production_now()
	return building.get_storage().amount(res_id) >= min_amount


func snapshot_roundtrip() -> GameSession:
	var snap := session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	session2.load_snapshot(snap)
	return session2


static func legacy_sqlite_fixture_path() -> String:
	return ProjectSettings.globalize_path("res://").path_join(REPO_SQLITE_FIXTURE).simplify_path()
