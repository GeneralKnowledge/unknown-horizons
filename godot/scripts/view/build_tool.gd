class_name BuildTool
extends RefCounted

signal building_placed(building: Building)

var session: GameSession
var building_id: int = GameConstants.BUILDINGS["LUMBERJACK"]
var active: bool = true
var tear_mode: bool = false


func _init(p_session: GameSession) -> void:
	session = p_session


func can_place_at(origin: Vector2i) -> bool:
	return placement_failure_reason(origin).is_empty()


func placement_failure_reason(origin: Vector2i) -> String:
	if session == null:
		return "No active session"
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building_id)
	)
	var terrain_reason := session.island.explain_placement_failure(
		building_id, export, origin, session.settlement
	)
	if not terrain_reason.is_empty():
		return terrain_reason
	if session.settlement != null:
		var cost_reason := BuildingCosts.describe_missing(session.settlement, building_id)
		if not cost_reason.is_empty():
			return cost_reason
	return ""


func try_place(origin: Vector2i) -> Building:
	if not active:
		return null
	if tear_mode:
		return _try_tear_at(origin)
	var cmd := BuildCommand.new(
		building_id, origin.x, origin.y, session.island, session.settlement
	)
	var building: Building = session.manager.execute(cmd) as Building
	if building != null:
		building_placed.emit(building)
	return building


func _try_tear_at(origin: Vector2i) -> Building:
	for b in session.get_buildings_on_island(session.island):
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(b.building_id)
		)
		for tile in BuildFootprint.origin_tiles(
			b.position, int(export.get("size_x", 1)), int(export.get("size_y", 1))
		):
			if tile == origin:
				session.manager.execute(TearCommand.new(b))
				return null
	return null


func set_palette_lumberjack() -> void:
	tear_mode = false
	building_id = GameConstants.BUILDINGS["LUMBERJACK"]


func set_palette_tree() -> void:
	tear_mode = false
	building_id = GameConstants.BUILDINGS["TREE"]


func set_palette_tear() -> void:
	tear_mode = true


func footprint_tiles(origin: Vector2i) -> Array:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building_id)
	)
	return BuildFootprint.origin_tiles(
		origin,
		int(export.get("size_x", 1)),
		int(export.get("size_y", 1))
	)
