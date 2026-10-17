class_name FieldBuilderComponent
extends RefCounted

## Stub — future: build fields around parent (see lumberjack FieldBuilder YAML).

var home_building: Building
var field_building_id: int = -1


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	field_building_id = int(config.get("field_building_id", -1))


func can_build_field_at(_origin: Vector2i) -> bool:
	return false
