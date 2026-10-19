class_name Building
extends RefCounted

var worldid: int
var building_id: int
var buildable_upon: bool = false
var position: Vector2i
var island: Island
var settlement: Settlement
var inventory: Inventory
var producer: Producer
var collecting: CollectingComponent
var health: HealthComponent
var field_builder: FieldBuilderComponent
var named: NamedComponent
var trade_post: TradePostComponent
var settler: LegacySettlerComponent


func _init(
	p_worldid: int,
	p_building_id: int,
	p_position: Vector2i,
	p_island: Island,
	p_settlement: Settlement,
	p_inventory: Inventory,
	p_producer: Producer
) -> void:
	worldid = p_worldid
	building_id = p_building_id
	position = p_position
	island = p_island
	settlement = p_settlement
	inventory = p_inventory
	producer = p_producer


func get_storage() -> Inventory:
	return inventory


func get_producer() -> Producer:
	return producer


func get_building_export() -> Dictionary:
	return ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))


func get_radius() -> int:
	return int(get_building_export().get("radius", 0))


## Legacy production.Farm — field buildings in radius that match consumed resources.
func get_providers() -> Array:
	if not BuildingRules.is_farm_building_id(building_id):
		return []
	if island == null or settlement == null:
		return []
	var reslist := get_consumed_resource_ids()
	if reslist.is_empty():
		return []
	var providers: Array = []
	for other in island.session.get_buildings_on_island(island):
		if other == self or other.settlement != settlement:
			continue
		if not BuildingRules.is_nature_field_building_id(other.building_id):
			continue
		if not _building_in_radius(other, get_radius()):
			continue
		if field_provides_any_resource(other, reslist):
			providers.append(other)
	return providers


func get_consumed_resource_ids() -> Array:
	var ids: Array = []
	if producer == null:
		return ids
	for line_key in producer.production_lines.keys():
		var data: Dictionary = producer.production_lines[line_key]
		for entry in data.get("consumes", []):
			var res_id := int(entry[0])
			if int(entry[1]) < 0 and res_id not in ids:
				ids.append(res_id)
	return ids


## Resources this building provides to collectors (legacy ResourceHandler.provided_resources).
func get_provided_resource_ids() -> Array:
	var ids: Array = []
	if producer == null:
		return ids
	for line_key in producer.production_lines.keys():
		var data: Dictionary = producer.production_lines[line_key]
		for entry in data.get("produces", []):
			var res_id := int(entry[0])
			if res_id not in ids:
				ids.append(res_id)
	return ids


## Legacy provider_by_resources: field counts only if it produces a farm-consumed resource.
static func field_provides_any_resource(field: Building, reslist: Array) -> bool:
	if reslist.is_empty():
		return false
	for provided_id in field.get_provided_resource_ids():
		if provided_id in reslist:
			return true
	return false


func _building_in_radius(other: Building, radius: int) -> bool:
	var self_export := get_building_export()
	var other_export := other.get_building_export()
	var self_borders := BuildFootprint.rect_borders(
		position,
		int(self_export.get("size_x", 1)),
		int(self_export.get("size_y", 1))
	)
	var other_origin := other.position
	var dist_sq := BuildFootprint._distance_point_to_rect_squared(other_origin, self_borders)
	if dist_sq <= radius * radius:
		return true
	for tile in BuildFootprint.origin_tiles(
		other_origin,
		int(other_export.get("size_x", 1)),
		int(other_export.get("size_y", 1))
	):
		if BuildFootprint._distance_point_to_rect_squared(tile as Vector2i, self_borders) <= radius * radius:
			return true
	return false
