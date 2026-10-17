class_name CommandManager
extends RefCounted

var session: GameSession
var _queue: Array[SimCommand] = []
var defer_to_tick_end: bool = false


func _init(p_session: GameSession) -> void:
	session = p_session


func execute(command: SimCommand, immediate: bool = true) -> Variant:
	if immediate or not defer_to_tick_end:
		return command.execute(session)
	_queue.append(command)
	return null


func flush() -> Array:
	var results: Array = []
	while not _queue.is_empty():
		var cmd: SimCommand = _queue.pop_front()
		results.append(cmd.execute(session))
	return results


func pending_count() -> int:
	return _queue.size()
