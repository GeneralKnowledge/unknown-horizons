class_name SimClock
extends RefCounted

## Fixed-rate sim stepping decoupled from render frame rate.

var _accum := 0.0


func reset() -> void:
	_accum = 0.0


func accumulate_and_run(session: GameSession, delta: float, on_tick: Callable = Callable()) -> int:
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	_accum += delta
	var ran := 0
	while _accum >= step:
		session.run_ticks(1)
		_accum -= step
		ran += 1
		if on_tick.is_valid():
			on_tick.call()
	return ran
