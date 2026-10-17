class_name BuildTool
extends RefCounted

signal building_placed(building: Building)

var session: GameSession
var building_id: int = GameConstants.BUILDINGS["LUMBERJACK"]
var active: bool = true


func _init(p_session: GameSession) -> void:
	session = p_session


func can_place_at(origin: Vector2i) -> bool:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building_id)
	)
	return session.island.can_place_building(building_id, export, origin, session.settlement)


func try_place(origin: Vector2i) -> Building:
	if not active:
		return null
	var cmd := BuildCommand.new(
		building_id, origin.x, origin.y, session.island, session.settlement
	)
	var building: Building = session.manager.execute(cmd) as Building
	if building != null:
		building_placed.emit(building)
	return building


func footprint_tiles(origin: Vector2i) -> Array:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building_id)
	)
	return BuildFootprint.origin_tiles(
		origin,
		int(export.get("size_x", 1)),
		int(export.get("size_y", 1))
	)
