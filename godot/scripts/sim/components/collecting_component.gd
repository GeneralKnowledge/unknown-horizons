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
	for unit_id in specs.keys():
		var count := int(specs[unit_id])
		for _i in range(count):
			collectors.append(
				CollectorRegistry.create_collector(int(unit_id), home_building, session)
			)


func tick_search_jobs() -> void:
	for collector in collectors:
		if (
			collector is BuildingCollector
			or collector is StorageCollector
			or collector is AnimalCollector
		):
			collector.search_job()
