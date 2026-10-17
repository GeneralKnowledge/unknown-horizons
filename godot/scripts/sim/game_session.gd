class_name GameSession
extends RefCounted

var timer: GameTimer
var scheduler: GameScheduler
var island: Island
var settlement: Settlement
var registry: EntityRegistry
var _next_worldid: int = 1
var _buildings: Dictionary = {}


func _init() -> void:
	timer = GameTimer.new()
	scheduler = GameScheduler.new(timer)
	registry = EntityRegistry.new()
	island = Island.new(allocate_worldid(), self)
	registry.register(island)
	var settlement_storage := PositiveSizedSpecializedInventory.new({
		GameConstants.RES["GOLD"]: 999999,
	})
	settlement = Settlement.new(allocate_worldid(), island, settlement_storage)
	island.settlements.append(settlement)
	registry.register(settlement)
	scheduler.before_ticking()


func load_test_map() -> void:
	island.load_ground(TestMapFactory.create_ground_map())
	settlement.init_buildability()


func allocate_worldid() -> int:
	var id := _next_worldid
	_next_worldid += 1
	return id


func register_building(building: Building) -> void:
	_buildings[building.worldid] = building
	registry.register(building)


func get_building(worldid: int) -> Building:
	return _buildings.get(worldid)


func run_ticks(ticks: int = 1) -> void:
	while ticks > 0:
		scheduler.tick(scheduler.cur_tick + 1)
		ticks -= 1


func run_seconds(seconds: float) -> void:
	run_ticks(timer.get_ticks(seconds))


func to_snapshot() -> Dictionary:
	var buildings: Array = []
	for b in _buildings.values():
		buildings.append({
			"worldid": b.worldid,
			"building_id": b.building_id,
			"x": b.position.x,
			"y": b.position.y,
			"storage": b.get_storage().get_stored_resources(),
			"producer_active": b.get_producer().is_active(),
		})
	return {"next_worldid": _next_worldid, "buildings": buildings}


func load_snapshot(data: Dictionary) -> void:
	for b in _buildings.values():
		island.release_tiles(b)
	_next_worldid = int(data.get("next_worldid", 1))
	_buildings.clear()
	settlement.buildings.clear()
	island.occupied_tiles.clear()
	settlement.init_buildability()
	var snaps: Array = data.get("buildings", [])
	snaps.sort_custom(func(a, b):
		if int(a["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return true
		if int(b["building_id"]) == GameConstants.BUILDINGS["WAREHOUSE"]:
			return false
		return int(a["worldid"]) < int(b["worldid"])
	)
	for snap in snaps:
		var building := BuildCommand.new(
			int(snap["building_id"]),
			int(snap["x"]),
			int(snap["y"]),
			island,
			settlement
		).execute(self, int(snap["worldid"]))
		if building == null:
			continue
		for res_key in snap.get("storage", {}).keys():
			building.get_storage().reset(int(res_key))
			building.get_storage().alter(int(res_key), int(snap["storage"][res_key]))
		if not bool(snap.get("producer_active", true)):
			building.get_producer().set_all_active(false)


static func settle() -> Dictionary:
	var session := GameSession.new()
	session.load_test_map()
	var settled := GameTestHelpers.settle(session)
	return {
		"session": session,
		"settlement": settled.settlement,
		"island": settled.island,
	}
