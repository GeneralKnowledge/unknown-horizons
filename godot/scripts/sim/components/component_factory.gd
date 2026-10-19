class_name ComponentFactory
extends RefCounted


static func create_storage(export: Dictionary) -> Inventory:
	return ContentLoader.create_storage_from_export(export)


static func create_producer_lines(export: Dictionary) -> Dictionary:
	return ContentLoader.create_producer_lines(export)


static func attach_to_building(
	building: Building,
	session: GameSession,
	export: Dictionary,
	attach_producer: bool = true,
	producer_auto_init: bool = true,
	defer_collecting: bool = false
) -> void:
	var components: Dictionary = export.get("components", {})
	if attach_producer and components.has("Producer"):
		var producer_cfg: Dictionary = components["Producer"]
		var lines := create_producer_lines(export)
		if not lines.is_empty():
			var util_kind := str(producer_cfg.get("utilization", "FullUtilization"))
			building.producer = Producer.new(
				building, session.scheduler, lines, producer_auto_init, util_kind
			)
	if not defer_collecting:
		var collecting := ContentLoader.create_collecting_from_export(export)
		if not collecting.is_empty():
			building.collecting = CollectingComponent.new(building, session, collecting)
	if components.has("Health"):
		building.health = HealthComponent.new(building, components["Health"])
	if components.has("Named"):
		building.named = NamedComponent.new(building, components["Named"])
	if components.has("TradePost"):
		building.trade_post = TradePostComponent.new(building, session.settlement.inventory)
	var baseclass: String = str(export.get("baseclass", ""))
	if baseclass.contains("Barracks") or baseclass.contains("UnitProduction"):
		if GameConstants.UNITS.has("SWORDSMAN"):
			var unit_id := int(GameConstants.UNITS["SWORDSMAN"])
			building.get_storage().add_resource_slot(unit_id, 5)
			building.set_meta(
				"unit_producer",
				UnitProducer.new(building, session, unit_id)
			)
	if components.has("FieldBuilder"):
		building.field_builder = FieldBuilderComponent.new(building, components["FieldBuilder"])
