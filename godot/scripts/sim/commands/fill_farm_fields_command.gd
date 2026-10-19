class_name FillFarmFieldsCommand
extends SimCommand

var farm: Building
var field_building_id: int = -1
var max_count: int = 8


func _init(p_farm: Building, p_field_building_id: int = -1, p_max_count: int = 8) -> void:
	farm = p_farm
	field_building_id = p_field_building_id
	max_count = p_max_count


func execute(session: GameSession) -> Variant:
	if farm == null:
		return 0
	return FarmFieldPlacement.place_surrounding_fields(
		session, farm, field_building_id, max_count
	)
