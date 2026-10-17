class_name Settlement
extends RefCounted

var worldid: int
var island: Island
var inventory: Inventory
var buildings: Array[Building] = []
var warehouse_origin: Vector2i = Vector2i.ZERO
var buildability: SettlementBuildabilityCache
var ground_map: Dictionary = {} # Vector2i -> Building or null (settlement build footprint)


func _init(p_worldid: int, p_island: Island, p_inventory: Inventory) -> void:
	worldid = p_worldid
	island = p_island
	inventory = p_inventory


func init_buildability() -> void:
	ground_map.clear()
	buildability = SettlementBuildabilityCache.new(island.terrain_cache, ground_map)


func register_warehouse(origin: Vector2i, footprint_tiles: Array, warehouse_radius: int) -> void:
	warehouse_origin = origin
	var sx := 3
	var sy := 3
	if not footprint_tiles.is_empty():
		var max_x := origin.x
		var max_y := origin.y
		for tile in footprint_tiles:
			var c: Vector2i = tile if tile is Vector2i else Vector2i(tile[0], tile[1])
			max_x = maxi(max_x, c.x)
			max_y = maxi(max_y, c.y)
		sx = max_x - origin.x + 1
		sy = max_y - origin.y + 1
	var center := origin + Vector2i(sx / 2, sy / 2)
	var circle := SimCircle.new(SimPoint.new(center.x, center.y), warehouse_radius)
	var land_tiles: Array = []
	for pair in circle.get_coordinates():
		var coords := Vector2i(int(pair[0]), int(pair[1]))
		if island.terrain_cache.land_or_coast.has(coords):
			land_tiles.append(coords)
			if not ground_map.has(coords):
				ground_map[coords] = null
	buildability.modify_area(land_tiles)


func can_place_building(origin: Vector2i, size: Vector2i) -> bool:
	if buildability == null:
		return false
	return buildability.can_place(origin, size)


func footprint_tiles_for(building: Building) -> Array:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building.building_id)
	)
	return BuildFootprint.origin_tiles(
		building.position,
		int(export.get("size_x", 1)),
		int(export.get("size_y", 1))
	)


func add_building(building: Building) -> void:
	if building not in buildings:
		buildings.append(building)
	var tiles := footprint_tiles_for(building)
	for tile in tiles:
		var c: Vector2i = tile if tile is Vector2i else Vector2i(tile[0], tile[1])
		ground_map[c] = building
	buildability.modify_area(tiles)


func remove_building(building: Building) -> void:
	var tiles := footprint_tiles_for(building)
	for tile in tiles:
		var c: Vector2i = tile if tile is Vector2i else Vector2i(tile[0], tile[1])
		if ground_map.get(c) == building:
			ground_map[c] = null
	buildability.modify_area(tiles)
	buildings.erase(building)
