class_name SettlementBuildabilityCache
extends BinaryBuildabilityCache

## Port of horizons/world/buildability/settlementcache.py

var settlement_ground_map: Dictionary = {} # Vector2i -> Building or null


func _init(p_terrain_cache: TerrainBuildabilityCache, p_ground_map: Dictionary) -> void:
	super._init(p_terrain_cache)
	settlement_ground_map = p_ground_map


func add_coords_on_land(coords_list: Array) -> void:
	var filtered: Array = []
	for coords in coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		if terrain_cache.land_or_coast.has(c):
			filtered.append(c)
	if not filtered.is_empty():
		add_area(filtered)


func modify_area(coords_list: Array) -> void:
	var land_or_coast := terrain_cache.land_or_coast
	var add_list: Array = []
	var remove_list: Array = []
	for coords in coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		if not land_or_coast.has(c) or not settlement_ground_map.has(c):
			continue
		var occupant: Building = settlement_ground_map[c]
		if occupant == null or BuildingRules.is_buildable_upon(occupant.building_id):
			if not coords_set.has(c):
				add_list.append(c)
		elif coords_set.has(c):
			remove_list.append(c)
	if not remove_list.is_empty():
		remove_area(remove_list)
	if not add_list.is_empty():
		super.add_area(add_list)
