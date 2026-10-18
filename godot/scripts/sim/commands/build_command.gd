class_name BuildCommand
extends SimCommand

var building_id: int
var x: int
var y: int
var island: Island
var settlement: Settlement
var ownerless: bool = false
var forced_worldid: int = -1
var skip_cost: bool = false
## When true, Producer is not attached until the caller finishes storage/production restore.
var defer_producer: bool = false


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


func execute(session: GameSession) -> Variant:
	if settlement == null and not ownerless:
		settlement = island.settlements[0]
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))
	var origin := Vector2i(x, y)
	if island.terrain_cache != null:
		if ownerless:
			if not island.can_place_ownerless(building_id, export, origin):
				return null
		elif not island.can_place_building(building_id, export, origin, settlement):
			return null
	if not ownerless and not skip_cost and settlement != null:
		var founding_warehouse := (
			building_id == GameConstants.BUILDINGS["WAREHOUSE"] and settlement.buildings.is_empty()
		)
		if not founding_warehouse:
			if not BuildingCosts.try_pay(settlement, building_id):
				return null
	var building := BuildingFactory.create_building(
		session, building_id, origin, island, settlement, forced_worldid, not defer_producer
	)
	if building == null:
		return null
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
		settlement.register_warehouse(origin, tiles, int(export.get("radius", 24)))
	MessageBus.building_placed.emit(building)
	MessageBus.settlement_updated.emit()
	return building
