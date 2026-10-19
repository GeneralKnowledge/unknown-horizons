class_name BuildCommand
extends SimCommand

const _FarmFields = preload("res://scripts/sim/world/farm_field_placement.gd")

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
## When true, CollectingComponent is not attached until collector restore from save.
var defer_collecting: bool = false
## When true, skip live buildability checks and place at saved coordinates (SQLite import).
var trust_legacy_placement: bool = false
## When true (default for farms), ring-placed crop fields are built after the farm.
var auto_place_farm_fields: bool = true


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
	if not trust_legacy_placement and island.terrain_cache != null:
		if ownerless:
			if not island.can_place_ownerless(building_id, export, origin):
				return null
		elif not island.can_place_building(building_id, export, origin, settlement):
			return null
		if building_id == GameConstants.BUILDINGS["TRAIL"] and _island_has_trail_building(island):
			if not island.trail_connects_to_network(origin, export, settlement):
				return null
	if not ownerless and not skip_cost and settlement != null:
		var founding_warehouse := (
			building_id == GameConstants.BUILDINGS["WAREHOUSE"] and settlement.buildings.is_empty()
		)
		if not founding_warehouse:
			if not BuildingCosts.try_pay(settlement, building_id):
				return null
	var building := BuildingFactory.create_building(
		session,
		building_id,
		origin,
		island,
		settlement,
		forced_worldid,
		not defer_producer,
		defer_collecting
	)
	if building == null:
		return null
	if settlement != null and not ownerless:
		settlement.add_building(building)
	island.occupies_tiles(building)
	if building_id == GameConstants.BUILDINGS["TRAIL"]:
		_apply_trail_road_tiles(island, origin, export)
	session.register_building(building)
	if building_id == GameConstants.BUILDINGS["WAREHOUSE"]:
		var tiles := BuildFootprint.origin_tiles(
			origin,
			int(export.get("size_x", 1)),
			int(export.get("size_y", 1))
		)
		settlement.register_warehouse(origin, tiles, int(export.get("radius", 24)))
		for tile in tiles:
			island.set_road_tile(tile)
	MessageBus.building_placed.emit(building)
	if (
		auto_place_farm_fields
		and building_id == GameConstants.BUILDINGS["FARM"]
		and building is Building
	):
		_FarmFields.place_surrounding_fields(session, building as Building)
	MessageBus.settlement_updated.emit()
	return building


static func _island_has_trail_building(island: Island) -> bool:
	for building in island.session.get_buildings_on_island(island):
		if building.building_id == GameConstants.BUILDINGS["TRAIL"]:
			return true
	return false


static func _apply_trail_road_tiles(island: Island, origin: Vector2i, export: Dictionary) -> void:
	var tiles := BuildFootprint.origin_tiles(
		origin,
		int(export.get("size_x", 1)),
		int(export.get("size_y", 1))
	)
	for tile in tiles:
		island.set_road_tile(tile)
