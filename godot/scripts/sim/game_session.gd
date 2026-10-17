class_name GameSession
extends RefCounted

const SNAPSHOT_VERSION := 3

var timer: GameTimer
var scheduler: GameScheduler
var island: Island
var settlement: Settlement
var registry: EntityRegistry
var manager: CommandManager
var _next_worldid: int = 1
var _buildings: Dictionary = {}
var _wild_animals: Dictionary = {}


func _init() -> void:
	timer = GameTimer.new()
	scheduler = GameScheduler.new(timer)
	registry = EntityRegistry.new()
	manager = CommandManager.new(self)
	island = Island.new(allocate_worldid(), self)
	registry.register(island)
	var slot_sizes: Dictionary = {}
	slot_sizes[GameConstants.RES["GOLD"]] = 999999
	for res_name in [
		"BOARDS", "TOOLS", "BRICKS", "FOOD", "CLAY", "IRON_INGOTS", "CHARCOAL", "TEXTILE",
	]:
		slot_sizes[GameConstants.RES[res_name]] = 999999
	var settlement_storage := PositiveSizedSpecializedInventory.new(slot_sizes)
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


func register_wild_animal(animal: WildAnimal) -> void:
	_wild_animals[animal.worldid] = animal
	registry.register(animal)


func get_wild_animals_on_island(p_island: Island) -> Array:
	var out: Array = []
	for a in _wild_animals.values():
		if a is WildAnimal and a.island == p_island:
			out.append(a)
	return out


func spawn_wild_animal(p_island: Island, x: int, y: int) -> WildAnimal:
	var export := ContentLoader.load_unit_export("deer")
	var inventory := ContentLoader.create_storage_from_unit_export(export)
	var lines := ContentLoader.create_producer_lines_from_unit(export)
	var animal := WildAnimal.new(
		allocate_worldid(), p_island, Vector2i(x, y), self, inventory, lines
	)
	register_wild_animal(animal)
	return animal


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
		"settlement_inventory": settlement.inventory.get_stored_resources(),
		"buildings": buildings,
	}


func load_snapshot(data: Dictionary) -> void:
	for b in _buildings.values():
		island.release_tiles(b)
		registry.unregister(b.worldid)
	for a in _wild_animals.values():
		registry.unregister(a.worldid)
	_next_worldid = int(data.get("next_worldid", 1))
	_buildings.clear()
	_wild_animals.clear()
	settlement.buildings.clear()
	island.occupied_tiles.clear()
	settlement.init_buildability()
	settlement.inventory.reset_all()
	if data.has("settlement_inventory"):
		var inv_data: Dictionary = data.get("settlement_inventory", {})
		for res_key in inv_data.keys():
			var res_id := int(str(res_key))
			settlement.inventory.alter(res_id, int(inv_data[res_key]))
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
