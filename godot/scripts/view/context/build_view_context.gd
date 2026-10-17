class_name BuildViewContext
extends BaseViewContext


func enter(manager: ViewContextManager) -> void:
	super.enter(manager)
	manager.build_tool.tear_mode = false
	manager.build_tool.active = true


func handle_input(event: InputEvent, manager: ViewContextManager) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid := manager.screen_to_grid(event.position)
		var reason := manager.build_tool.placement_failure_reason(grid)
		if not reason.is_empty():
			MessageBus.build_feedback.emit(reason, true)
			return true
		var placed := manager.build_tool.try_place(grid)
		if placed != null:
			MessageBus.building_selected.emit(placed)
			MessageBus.build_feedback.emit("Placed %s" % ContentLoader.stem_for_building_id(placed.building_id), false)
			return true
	return false

