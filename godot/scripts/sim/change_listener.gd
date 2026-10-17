class_name ChangeListener
extends RefCounted

var _listeners: Array[Callable] = []


func add_change_listener(listener: Callable) -> void:
	if listener not in _listeners:
		_listeners.append(listener)


func discard_change_listener(listener: Callable) -> void:
	_listeners.erase(listener)


func clear_change_listeners() -> void:
	_listeners.clear()


func _changed() -> void:
	for listener in _listeners:
		listener.call()
