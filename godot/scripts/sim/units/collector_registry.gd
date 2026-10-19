class_name CollectorRegistry
extends RefCounted

const FieldCollectorScript = preload("res://scripts/sim/units/field_collector.gd")

## Maps exported unit baseclass → collector implementation.


static func create_collector(
	unit_type_id: int,
	home_building: Building,
	session: GameSession,
	legacy_unit_worldid: int = -1
) -> Variant:
	var collector: Variant
	if home_building.building_id == GameConstants.BUILDINGS["WAREHOUSE"]:
		collector = StorageCollector.new(home_building, session, unit_type_id)
	else:
		var stem := ContentLoader.stem_for_unit_id(unit_type_id)
		var export := ContentLoader.load_unit_export(stem)
		var baseclass: String = str(export.get("baseclass", ""))
		if baseclass.ends_with("HunterCollector"):
			collector = AnimalCollector.new(home_building, session, unit_type_id)
		elif baseclass.ends_with("StorageCollector"):
			collector = StorageCollector.new(home_building, session, unit_type_id)
		elif baseclass.ends_with("FieldCollector"):
			collector = FieldCollectorScript.new(home_building, session, unit_type_id)
		else:
			collector = BuildingCollector.new(home_building, session, unit_type_id)
	if collector is BuildingCollector and legacy_unit_worldid > 0:
		collector.legacy_unit_worldid = legacy_unit_worldid
	return collector
