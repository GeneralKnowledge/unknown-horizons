class_name FarmFieldPlacement
extends RefCounted

## Standard farm ring (legacy tests/game/test_buildings._build_farm layout).

const FIELD_OFFSETS: Array[Vector2i] = [
	Vector2i(-3, -3),
	Vector2i(-3, 0),
	Vector2i(-3, 3),
	Vector2i(0, 3),
	Vector2i(3, 3),
	Vector2i(3, 0),
	Vector2i(3, -3),
	Vector2i(0, -3),
]

static var _field_id_by_produced_resource: Dictionary = {}


static func place_surrounding_fields(
	session: GameSession,
	farm: Building,
	field_building_id: int = -1,
	max_count: int = 8
) -> int:
	if farm == null or session == null:
		return 0
	if not BuildingRules.is_farm_building_id(farm.building_id):
		return 0
	var field_id := field_building_id
	if field_id < 0:
		field_id = default_field_id_for_farm(farm)
	if field_id < 0:
		return 0
	var limit := mini(maxi(max_count, 0), FIELD_OFFSETS.size())
	var built := 0
	for i in range(limit):
		var off: Vector2i = FIELD_OFFSETS[i]
		var origin := farm.position + off
		if not _can_place_field(farm, field_id, origin):
			continue
		if not BuildingCosts.can_afford(farm.settlement, field_id):
			break
		var field: Building = session.manager.execute(
			BuildCommand.new(field_id, origin.x, origin.y, farm.island, farm.settlement)
		) as Building
		if field != null:
			built += 1
	return built


static func default_field_id_for_farm(farm: Building) -> int:
	for res_id in farm.get_consumed_resource_ids():
		var field_id := field_building_id_for_crop_resource(int(res_id))
		if field_id > 0:
			return field_id
	return -1


static func field_building_id_for_crop_resource(produced_resource_id: int) -> int:
	_ensure_field_map()
	return int(_field_id_by_produced_resource.get(produced_resource_id, -1))


static func _ensure_field_map() -> void:
	if not _field_id_by_produced_resource.is_empty():
		return
	for name in GameConstants.BUILDINGS:
		var building_id := int(GameConstants.BUILDINGS[name])
		if not BuildingRules.is_nature_field_building_id(building_id):
			continue
		var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))
		var producer_cfg: Dictionary = export.get("components", {}).get("Producer", {})
		var lines: Dictionary = producer_cfg.get("productionlines", {})
		for line_key in lines.keys():
			var data: Dictionary = lines[line_key]
			for entry in data.get("produces", []):
				var res_id := int(entry[0])
				if not _field_id_by_produced_resource.has(res_id):
					_field_id_by_produced_resource[res_id] = building_id


static func _can_place_field(farm: Building, field_building_id: int, origin: Vector2i) -> bool:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(field_building_id)
	)
	return farm.island.can_place_building(field_building_id, export, origin, farm.settlement)
