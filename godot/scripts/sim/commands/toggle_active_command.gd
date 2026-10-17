class_name ToggleActiveCommand
extends SimCommand

var building: Building


func _init(p_building: Building) -> void:
	building = p_building


func execute(session: GameSession) -> Variant:
	if building == null:
		return false
	var producer := building.get_producer()
	if producer == null:
		return false
	producer.toggle_active()
	return true
