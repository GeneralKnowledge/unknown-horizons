class_name BuildCommand
extends RefCounted

var building_id: int
var x: int
var y: int
var island: Island
var settlement: Settlement
var ownerless: bool = false


func _init(
	p_building_id: int,
	p_x: int,
	p_y: int,
	p_island: Island,
	p_settlement: Settlement = null,
	p_ownerless: bool = false
) -> void:
	building_id = p_building_id
	x = p_x
	y = p_y
	island = p_island
	settlement = p_settlement
	ownerless = p_ownerless


func execute(session: GameSession, forced_worldid: int = -1) -> Building:
	if settlement == null and not ownerless:
		settlement = island.settlements[0]
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))
	var origin := Vector2i(x, y)
	if island.terrain_cache != null:
		if ownerless:
			if not island.terrain_cache.can_place_land(origin, Vector2i(int(export.get("size_x", 1)), int(export.get("size_y", 1)))):
				return null
		elif not island.can_place_building(export, origin, settlement):
			return null
	var inventory := ContentLoader.create_storage_from_export(export)
	var lines := ContentLoader.create_producer_lines(export)
	var worldid := forced_worldid if forced_worldid > 0 else session.allocate_worldid()
	var building := Building.new(
		worldid,
		building_id,
		origin,
		island,
		settlement,
		inventory,
		null
	)
	var producer := Producer.new(building, session.scheduler, lines)
	building.producer = producer
	if settlement != null and not ownerless:
		settlement.add_building(building)
	island.occupies_tiles(building)
	session.register_building(building)
	if building_id == GameConstants.BUILDINGS["WAREHOUSE"]:
		var tiles := BuildFootprint.origin_tiles(
			origin,
			int(export.get("size_x", 1)),
			int(export.get("size_y", 1))
		)
		settlement.register_warehouse(origin, tiles)
	return building
