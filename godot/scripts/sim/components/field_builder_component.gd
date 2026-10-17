class_name FieldBuilderComponent
extends RefCounted

## Stub — future: build fields around parent (see lumberjack FieldBuilder YAML).

var home_building: Building
var field_building_id: int = -1


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	field_building_id = int(config.get("field_building_id", -1))


func can_build_field_at(origin: Vector2i) -> bool:
	if home_building == null or field_building_id < 0:
		return false
	var island: Island = home_building.island
	var settlement: Settlement = home_building.settlement
	if island == null or settlement == null:
		return false
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(field_building_id)
	)
	var sx := int(export.get("size_x", 1))
	var sy := int(export.get("size_y", 1))
	return island.can_place_building(field_building_id, export, origin, settlement)


func try_build_field_at(session: GameSession, origin: Vector2i) -> Building:
	if not can_build_field_at(origin):
		return null
	return session.manager.execute(
		BuildCommand.new(field_building_id, origin.x, origin.y, home_building.island, home_building.settlement)
	) as Building
