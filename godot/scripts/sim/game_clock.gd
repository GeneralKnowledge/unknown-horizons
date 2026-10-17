class_name GameClock
extends RefCounted

## Wall-clock driven tick pump (port of horizons/timer.py check_tick).

enum TestResult { TEST_PASS, TEST_SKIP }

const ACCEPTABLE_TICK_DELAY := 0.2
const DEFER_TICK_ON_DELAY_BY := 0.4

var ticks_per_second: int = GameTimer.TICKS_PER_SECOND
var tick_next_id: int = 0
var tick_next_time: float = 0.0
var freeze_protection: bool = false
var tick_func_test: Array[Callable] = []
var tick_func_call: Array[Callable] = []

var _time_source: Callable = Time.get_unix_time_from_system


func _init(
	p_tick_next_id: int = 0,
	p_freeze_protection: bool = false,
	p_time_source: Callable = Callable()
) -> void:
	tick_next_id = p_tick_next_id
	freeze_protection = p_freeze_protection
	if p_time_source.is_valid():
		_time_source = p_time_source


func set_time_source(source: Callable) -> void:
	_time_source = source


func _now() -> float:
	return float(_time_source.call())


func add_test(callable: Callable) -> void:
	tick_func_test.append(callable)


func add_call(callable: Callable) -> void:
	tick_func_call.append(callable)


func remove_call(callable: Callable) -> void:
	tick_func_call.erase(callable)


func get_ticks(seconds: float) -> int:
	return int(round(seconds * float(ticks_per_second)))


func check_tick(max_ticks: Variant = null) -> void:
	if ticks_per_second == 0:
		return
	while _now() >= tick_next_time and (max_ticks == null or tick_next_id <= int(max_ticks)):
		for test_cb in tick_func_test:
			var r: int = int(test_cb.call(tick_next_id))
			if r == TestResult.TEST_SKIP:
				if ticks_per_second != 0:
					tick_next_time = (tick_next_time if tick_next_time > 0.0 else _now()) + 1.0 / float(ticks_per_second)
				return
		if freeze_protection and tick_next_time > 0.0:
			var diff := _now() - tick_next_time
			if diff > ACCEPTABLE_TICK_DELAY:
				tick_next_time += DEFER_TICK_ON_DELAY_BY
		for call_cb in tick_func_call:
			call_cb.call(tick_next_id)
		tick_next_id += 1
		if ticks_per_second == 0:
			return
		tick_next_time = (tick_next_time if tick_next_time > 0.0 else _now()) + 1.0 / float(ticks_per_second)
