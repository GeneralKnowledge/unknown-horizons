class_name FieldBuilderComponent
extends RefCounted

## Legacy FieldBuilder — fill building radius with 1×1 field buildings (e.g. lumberjack trees).

var home_building: Building
var field_building_id: int = -1


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	field_building_id = int(config.get("field_building_id", -1))


func how_many() -> int:
	return coords_in_range().size()


func total_cost() -> Dictionary:
	var per := BuildingCosts.costs_for_building_id(field_building_id)
	var count := how_many()
	var total: Dictionary = {}
	for res_id in per.keys():
		total[int(res_id)] = int(per[res_id]) * count
	return total


func can_afford_fill() -> bool:
	if home_building == null or home_building.settlement == null:
		return false
	return BuildingCosts.can_afford_costs(home_building.settlement, total_cost())


func coords_in_range() -> Array:
	var out: Array = []
	if home_building == null or field_building_id < 0:
		return out
	var export := home_building.get_building_export()
	var radius := int(export.get("radius", 0))
	var sx := int(export.get("size_x", 1))
	var sy := int(export.get("size_y", 1))
	for origin in BuildFootprint.placement_origins_in_radius(
		home_building.position, sx, sy, radius, false
	):
		var pt: Vector2i = origin as Vector2i
		if can_build_field_at(pt):
			out.append(pt)
	return out


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


## Legacy fill_range — all coords at once if total cost is affordable.
func fill_range(session: GameSession) -> int:
	if not can_afford_fill():
		return 0
	var coords := coords_in_range()
	if coords.is_empty():
		return 0
	var built := 0
	for origin in coords:
		var pt: Vector2i = origin as Vector2i
		if try_build_field_at(session, pt) != null:
			built += 1
	return built
