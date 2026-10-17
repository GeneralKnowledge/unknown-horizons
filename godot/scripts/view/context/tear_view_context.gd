class_name TearViewContext
extends BaseViewContext


func enter(manager: ViewContextManager) -> void:
	super.enter(manager)
	manager.build_tool.set_palette_tear()


func handle_input(event: InputEvent, manager: ViewContextManager) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid := manager.screen_to_grid(event.position)
		manager.build_tool.try_place(grid)
		return true
	return false
