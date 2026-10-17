class_name CollectingComponent
extends RefCounted

var home_building: Building
var session: GameSession
var collector_specs: Dictionary = {} # unit_id -> count
var collectors: Array = []


func _init(p_building: Building, p_session: GameSession, specs: Dictionary) -> void:
	home_building = p_building
	session = p_session
	collector_specs = specs
	var use_storage := home_building.building_id == GameConstants.BUILDINGS["WAREHOUSE"]
	for unit_id in specs.keys():
		var count := int(specs[unit_id])
		for _i in range(count):
			if use_storage:
				collectors.append(StorageCollector.new(home_building, session, int(unit_id)))
			elif int(unit_id) == GameConstants.UNITS["HUNTER_COLLECTOR"]:
				collectors.append(AnimalCollector.new(home_building, session, int(unit_id)))
			else:
				collectors.append(BuildingCollector.new(home_building, session, int(unit_id)))


func tick_search_jobs() -> void:
	for collector in collectors:
		if (
			collector is BuildingCollector
			or collector is StorageCollector
			or collector is AnimalCollector
		):
			collector.search_job()
