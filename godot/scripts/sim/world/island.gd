class_name Island
extends RefCounted

var worldid: int
var session: GameSession
var settlements: Array[Settlement] = []
var ground_map: Dictionary = {} # Vector2i -> SimGround.Kind
var terrain_cache: TerrainBuildabilityCache
var occupied_tiles: Dictionary = {} # Vector2i -> Building


func _init(p_worldid: int, p_session: GameSession) -> void:
	worldid = p_worldid
	session = p_session


func load_ground(map_data: Dictionary) -> void:
	ground_map = map_data.duplicate(true)
	var land := CoordSet.new()
	for coords in ground_map.keys():
		if int(ground_map[coords]) == SimGround.Kind.LAND:
			land.add(coords)
	terrain_cache = TerrainBuildabilityCache.new(land)


func get_ground(coords: Vector2i) -> int:
	return int(ground_map.get(coords, SimGround.Kind.DEEP_WATER))


func is_land(coords: Vector2i) -> bool:
	return get_ground(coords) == SimGround.Kind.LAND


func get_island_at(point: Vector2i) -> Island:
	if ground_map.has(point):
		return self
	return null


func occupies_tiles(building: Building) -> void:
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building.building_id))
	var sx := int(export.get("size_x", 1))
	var sy := int(export.get("size_y", 1))
	for tile in BuildFootprint.origin_tiles(building.position, sx, sy):
		occupied_tiles[tile] = building


func release_tiles(building: Building) -> void:
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building.building_id))
	var sx := int(export.get("size_x", 1))
	var sy := int(export.get("size_y", 1))
	for tile in BuildFootprint.origin_tiles(building.position, sx, sy):
		if occupied_tiles.get(tile) == building:
			occupied_tiles.erase(tile)


func can_place_building(export: Dictionary, origin: Vector2i, settlement: Settlement) -> bool:
	var sx := int(export.get("size_x", 1))
	var sy := int(export.get("size_y", 1))
	var size := Vector2i(sx, sy)
	if not terrain_cache.can_place_land(origin, size):
		return false
	for tile in BuildFootprint.origin_tiles(origin, sx, sy):
		if occupied_tiles.has(tile):
			return false
	if settlement != null:
		if settlement.buildings.is_empty():
			return true
		if not settlement.can_place_building(origin, size):
			return false
	return true
