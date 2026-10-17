class_name Settlement
extends RefCounted

var worldid: int
var island: Island
var inventory: Inventory
var buildings: Array[Building] = []
var warehouse_origin: Vector2i = Vector2i.ZERO
var buildability: BinaryBuildabilityCache
var _full_island_build: bool = false


func _init(p_worldid: int, p_island: Island, p_inventory: Inventory) -> void:
	worldid = p_worldid
	island = p_island
	inventory = p_inventory


func init_buildability() -> void:
	buildability = BinaryBuildabilityCache.new(island.terrain_cache)


func register_warehouse(origin: Vector2i, footprint_tiles: Array) -> void:
	warehouse_origin = origin
	buildability.add_area(footprint_tiles)
	_full_island_build = true


func can_place_building(origin: Vector2i, size: Vector2i) -> bool:
	if buildability == null:
		return false
	if _full_island_build:
		for tile in BuildFootprint.origin_tiles(origin, size.x, size.y):
			if not island.is_land(tile):
				return false
		return true
	return buildability.can_place(origin, size)


func add_building(building: Building) -> void:
	if building not in buildings:
		buildings.append(building)
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building.building_id))
	var tiles := BuildFootprint.origin_tiles(
		building.position,
		int(export.get("size_x", 1)),
		int(export.get("size_y", 1))
	)
	buildability.add_area(tiles)
