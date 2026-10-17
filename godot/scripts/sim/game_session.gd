class_name GameSession
extends RefCounted

const SNAPSHOT_VERSION := 2

var timer: GameTimer
var scheduler: GameScheduler
var island: Island
var settlement: Settlement
var registry: EntityRegistry
var manager: CommandManager
var _next_worldid: int = 1
var _buildings: Dictionary = {}


func _init() -> void:
	timer = GameTimer.new()
	scheduler = GameScheduler.new(timer)
	registry = EntityRegistry.new()
	manager = CommandManager.new(self)
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


func get_buildings_on_island(p_island: Island) -> Array:
	var out: Array = []
	for b in _buildings.values():
		if b is Building and b.island == p_island:
			out.append(b)
	return out


func run_ticks(ticks: int = 1) -> void:
	while ticks > 0:
		scheduler.tick(scheduler.cur_tick + 1)
		manager.flush()
		ticks -= 1


func run_seconds(seconds: float) -> void:
	run_ticks(timer.get_ticks(seconds))


func to_snapshot() -> Dictionary:
	var buildings: Array = []
	for b in _buildings.values():
		var entry := {
			"worldid": b.worldid,
			"building_id": b.building_id,
			"x": b.position.x,
			"y": b.position.y,
			"storage": b.get_storage().get_stored_resources(),
		}
		var producer: Producer = b.get_producer()
		if producer != null:
			entry["producer_active"] = producer.is_active()
		buildings.append(entry)
	return {
		"schema_version": SNAPSHOT_VERSION,
		"next_worldid": _next_worldid,
		"buildings": buildings,
	}


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
		var cmd := BuildCommand.new(
			int(snap["building_id"]),
			int(snap["x"]),
			int(snap["y"]),
			island,
			settlement
		)
		cmd.forced_worldid = int(snap["worldid"])
		var building: Building = cmd.execute(self)
		if building == null:
			continue
		var storage_data: Dictionary = snap.get("storage", {})
		for res_key in storage_data.keys():
			var res_id := int(str(res_key))
			building.get_storage().reset(res_id)
			building.get_storage().alter(res_id, int(storage_data[res_key]))
		var producer: Producer = building.get_producer()
		if producer != null and not bool(snap.get("producer_active", true)):
			producer.set_all_active(false)


static func settle() -> Dictionary:
	var session := GameSession.new()
	session.load_test_map()
	var settled := GameTestHelpers.settle(session)
	return {
		"session": session,
		"settlement": settled.settlement,
		"island": settled.island,
	}
