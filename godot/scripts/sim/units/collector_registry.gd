class_name CollectorRegistry
extends RefCounted

## Maps exported unit baseclass → collector implementation.


static func create_collector(
	unit_type_id: int,
	home_building: Building,
	session: GameSession
) -> Variant:
	if home_building.building_id == GameConstants.BUILDINGS["WAREHOUSE"]:
		return StorageCollector.new(home_building, session, unit_type_id)
	var stem := ContentLoader.stem_for_unit_id(unit_type_id)
	var export := ContentLoader.load_unit_export(stem)
	var baseclass: String = str(export.get("baseclass", ""))
	if baseclass.ends_with("HunterCollector"):
		return AnimalCollector.new(home_building, session, unit_type_id)
	if baseclass.ends_with("StorageCollector"):
		return StorageCollector.new(home_building, session, unit_type_id)
	# FieldCollector, BuildingCollector, LumberjackCollector, …
	return BuildingCollector.new(home_building, session, unit_type_id)
