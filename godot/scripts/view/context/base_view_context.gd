class_name BaseViewContext
extends RefCounted

## View-only interaction mode (no sim mutation).

var is_active: bool = false


func enter(_manager: ViewContextManager) -> void:
	is_active = true


func exit(_manager: ViewContextManager) -> void:
	is_active = false


func handle_input(_event: InputEvent, _manager: ViewContextManager) -> bool:
	return false
