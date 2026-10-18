class_name CollectingComponent
extends RefCounted

var home_building: Building
var session: GameSession
var collector_specs: Dictionary = {} # unit_id -> count
var collectors: Array = []


func _init(
	p_building: Building,
	p_session: GameSession,
	specs: Dictionary,
	spawn_from_yaml_specs: bool = true
) -> void:
	home_building = p_building
	session = p_session
	collector_specs = specs
	collectors = []
	if not spawn_from_yaml_specs:
		return
	for unit_id in specs.keys():
		var count := int(specs[unit_id])
		for _i in range(count):
			collectors.append(
				CollectorRegistry.create_collector(int(unit_id), home_building, session)
			)


## Restore collectors from legacy save rows (one sim collector per save row; save wins over YAML).
static func attach_from_save_rows(
	p_building: Building,
	p_session: GameSession,
	specs: Dictionary,
	save_rows: Array
) -> CollectingComponent:
	var comp := CollectingComponent.new(p_building, p_session, specs, false)
	for row in save_rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var unit_type_id := int(row.get("unit_type_id", -1))
		if unit_type_id < 0:
			continue
		comp.collectors.append(
			CollectorRegistry.create_collector(unit_type_id, p_building, p_session)
		)
	p_building.collecting = comp
	return comp


func tick_search_jobs() -> void:
	for collector in collectors:
		if (
			collector is BuildingCollector
			or collector is StorageCollector
			or collector is AnimalCollector
		):
			collector.search_job()
