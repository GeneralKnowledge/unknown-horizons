class_name GameSession
extends RefCounted

var timer: GameTimer
var scheduler: GameScheduler
var island: Island
var settlement: Settlement
var _next_worldid: int = 1
var _buildings: Dictionary = {}


func _init() -> void:
	timer = GameTimer.new()
	scheduler = GameScheduler.new(timer)
	island = Island.new(allocate_worldid(), self)
	var settlement_storage := PositiveSizedSpecializedInventory.new({
		GameConstants.RES["GOLD"]: 999999,
	})
	settlement = Settlement.new(allocate_worldid(), island, settlement_storage)
	island.settlements.append(settlement)
	scheduler.before_ticking()


func allocate_worldid() -> int:
	var id := _next_worldid
	_next_worldid += 1
	return id


func register_building(building: Building) -> void:
	_buildings[building.worldid] = building


func run_ticks(ticks: int = 1) -> void:
	while ticks > 0:
		scheduler.tick(scheduler.cur_tick + 1)
		ticks -= 1


func run_seconds(seconds: float) -> void:
	run_ticks(timer.get_ticks(seconds))


static func settle() -> Dictionary:
	var session := GameSession.new()
	return {"session": session, "settlement": session.settlement, "island": session.island}
