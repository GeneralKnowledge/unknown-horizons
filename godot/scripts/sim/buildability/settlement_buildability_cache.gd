class_name SettlementBuildabilityCache
extends BinaryBuildabilityCache

## Port of horizons/world/buildability/settlementcache.py (simplified).


func add_coords_on_land(coords_list: Array) -> void:
	var filtered: Array = []
	for coords in coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		if terrain_cache.land_or_coast.has(c):
			filtered.append(c)
	if not filtered.is_empty():
		add_area(filtered)
