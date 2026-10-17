class_name BuildingRules
extends RefCounted

## Placement rules — prefer exported building JSON, fallback to legacy lists.


static func is_buildable_upon_building_id(building_id: int) -> bool:
	var stem := ContentLoader.stem_for_building_id(building_id)
	var export := ContentLoader.load_building_export(stem)
	if export.has("buildable_upon"):
		return bool(export["buildable_upon"])
	return _legacy_buildable_upon(building_id)


static func is_buildable_upon(building_id: int) -> bool:
	return is_buildable_upon_building_id(building_id)


static func terrain_requirement(building_id: int) -> int:
	var stem := ContentLoader.stem_for_building_id(building_id)
	var export := ContentLoader.load_building_export(stem)
	if export.has("terrain_requirement"):
		return int(export["terrain_requirement"])
	return _legacy_terrain_requirement(building_id)


static func _legacy_buildable_upon(building_id: int) -> bool:
	const UPON: Array = [
		GameConstants.BUILDINGS["TREE"],
		GameConstants.BUILDINGS["TRAIL"],
		GameConstants.BUILDINGS["FISH_DEPOSIT"],
		GameConstants.BUILDINGS["CLAY_DEPOSIT"],
		GameConstants.BUILDINGS["MOUNTAIN"],
		GameConstants.BUILDINGS["AMBIENT"],
	]
	return building_id in UPON


static func _legacy_terrain_requirement(building_id: int) -> int:
	const COAST: Array = [
		GameConstants.BUILDINGS["FISHER"],
		GameConstants.BUILDINGS["SALT_PONDS"],
	]
	if building_id in COAST:
		return TerrainRequirement.LAND_AND_COAST
	return TerrainRequirement.LAND
