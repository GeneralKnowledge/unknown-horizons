class_name BuildingRules
extends RefCounted

## Placement rules until export carries buildable_upon.


static func is_buildable_upon(building_id: int) -> bool:
	const UPON: Array = [
		GameConstants.BUILDINGS["TREE"],
		GameConstants.BUILDINGS["TRAIL"],
		GameConstants.BUILDINGS["FISH_DEPOSIT"],
		GameConstants.BUILDINGS["CLAY_DEPOSIT"],
		GameConstants.BUILDINGS["MOUNTAIN"],
		GameConstants.BUILDINGS["AMBIENT"],
	]
	return building_id in UPON
