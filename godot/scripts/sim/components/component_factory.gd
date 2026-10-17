class_name ComponentFactory
extends RefCounted


static func create_storage(export: Dictionary) -> Inventory:
	return ContentLoader.create_storage_from_export(export)


static func create_producer_lines(export: Dictionary) -> Dictionary:
	return ContentLoader.create_producer_lines(export)


static func attach_to_building(building: Building, session: GameSession, export: Dictionary) -> void:
	var components: Dictionary = export.get("components", {})
	if components.has("Producer"):
		var lines := create_producer_lines(export)
		if not lines.is_empty():
			building.producer = Producer.new(building, session.scheduler, lines)
	var collecting := ContentLoader.create_collecting_from_export(export)
	if not collecting.is_empty():
		building.collecting = CollectingComponent.new(building, session, collecting)
	if components.has("Health"):
		building.health = HealthComponent.new(building, components["Health"])
	if components.has("FieldBuilder"):
		building.field_builder = FieldBuilderComponent.new(building, components["FieldBuilder"])
