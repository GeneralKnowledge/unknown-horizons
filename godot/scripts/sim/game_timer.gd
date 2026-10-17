class_name GameTimer
extends RefCounted

## Wall-clock to game-tick conversion (mirrors horizons/timer.py get_ticks).

const TICKS_PER_SECOND := 16

var tick_next_id: int = 0
var tick_callbacks: Array[Callable] = []


func get_ticks(seconds: float) -> int:
	return int(round(seconds * float(TICKS_PER_SECOND)))


func add_call(callable: Callable) -> void:
	tick_callbacks.append(callable)


func remove_call(callable: Callable) -> void:
	tick_callbacks.erase(callable)


func advance_tick(tick_id: int) -> void:
	for cb in tick_callbacks:
		cb.call(tick_id)
