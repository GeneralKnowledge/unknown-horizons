class_name TearCommand
extends SimCommand

var building: Building


func _init(p_building: Building) -> void:
	building = p_building


func execute(session: GameSession) -> Variant:
	if building == null:
		return false
	if building.collecting != null:
		for collector in building.collecting.collectors:
			session.scheduler.rem_all_classinst_calls(collector)
	if building.building_id == GameConstants.BUILDINGS["TRAIL"]:
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(building.building_id)
		)
		var origin: Vector2i = building.position
		for tile in BuildFootprint.origin_tiles(
			origin,
			int(export.get("size_x", 1)),
			int(export.get("size_y", 1))
		):
			building.island.set_road_tile(tile, false)
	building.island.unregister_resource_provider(building)
	building.island.release_tiles(building)
	if building.settlement != null:
		building.settlement.remove_building(building)
	session.registry.unregister(building.worldid)
	session._buildings.erase(building.worldid)
	building.producer = null
	building.collecting = null
	MessageBus.building_removed.emit(building)
	MessageBus.settlement_updated.emit()
	return true
