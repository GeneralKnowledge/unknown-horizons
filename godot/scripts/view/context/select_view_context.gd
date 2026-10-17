class_name SelectViewContext
extends BaseViewContext


func handle_input(event: InputEvent, manager: ViewContextManager) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var grid := manager.screen_to_grid(event.position)
		var picked := manager.pick_building_at(grid)
		if picked != null:
			MessageBus.building_selected.emit(picked)
			return true
	return false
