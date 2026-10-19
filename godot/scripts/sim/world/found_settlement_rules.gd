class_name FoundSettlementRules
extends RefCounted

## Legacy ship → warehouse founding preconditions (shiptabs + Build settlement).


static func is_unfounded(settlement: Settlement) -> bool:
	return settlement != null and settlement.buildings.is_empty()


static func ship_near_warehouse_site(ship: LegacyUnit, warehouse_origin: Vector2i) -> bool:
	if ship == null:
		return false
	var max_dist := maxi(ship.radius, 1) + 3
	var dx := absi(ship.position.x - warehouse_origin.x)
	var dy := absi(ship.position.y - warehouse_origin.y)
	return maxi(dx, dy) <= max_dist


static func can_place_founding_warehouse(
	island: Island,
	settlement: Settlement,
	building_id: int,
	origin: Vector2i
) -> bool:
	var export := ContentLoader.load_building_export(ContentLoader.stem_for_building_id(building_id))
	return island.explain_placement_failure(building_id, export, origin, settlement).is_empty()
