class_name BuildingFactory
extends RefCounted


static func create_building(
	session: GameSession,
	building_id: int,
	origin: Vector2i,
	island: Island,
	settlement: Settlement,
	forced_worldid: int = -1
) -> Building:
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))
	var inventory := ContentLoader.create_storage_from_export(export)
	var lines := ContentLoader.create_producer_lines(export)
	var worldid := forced_worldid if forced_worldid > 0 else session.allocate_worldid()
	var building := Building.new(
		worldid,
		building_id,
		origin,
		island,
		settlement,
		inventory,
		null
	)
	if not lines.is_empty():
		building.producer = Producer.new(building, session.scheduler, lines)
	var collecting := ContentLoader.create_collecting_from_export(export)
	if not collecting.is_empty():
		building.collecting = CollectingComponent.new(building, session, collecting)
	return building
