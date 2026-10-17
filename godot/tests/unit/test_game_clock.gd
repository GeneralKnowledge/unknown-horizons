extends GutTest

const TICK_START := 0
const TICK_PER_SEC := GameTimer.TICKS_PER_SECOND
const TIME_START := 1000.0
const TIME_TICK := 1.0 / float(TICK_PER_SEC)

var _clock_time := TIME_START
var _timer: GameClock
var _callback_count := 0
var _last_tick := -1


func before_each() -> void:
	_clock_time = TIME_START
	_callback_count = 0
	_last_tick = -1
	_timer = GameClock.new(TICK_START, false, func(): return _clock_time)
	_timer.ticks_per_second = TICK_PER_SEC
	_timer.add_call(_on_tick)


func _on_tick(tick_id: int) -> void:
	_callback_count += 1
	_last_tick = tick_id


func test_activate_register_end_unregister_from_pump() -> void:
	assert_false(_timer.is_registered_with_pump())
	_timer.activate()
	assert_true(_timer.is_registered_with_pump())
	_timer.end()
	assert_false(_timer.is_registered_with_pump())


func test_first_pump_then_one_tick() -> void:
	_timer.check_tick()
	assert_eq(1, _callback_count)
	assert_eq(TICK_START, _last_tick)


func test_two_pump_same_time_only_one_tick() -> void:
	_timer.check_tick()
	_timer.check_tick()
	assert_eq(1, _callback_count)


func test_two_pump_with_delay_then_two_ticks() -> void:
	_timer.check_tick()
	_clock_time = TIME_START + TIME_TICK
	_timer.check_tick()
	assert_eq(2, _callback_count)
	assert_eq(TICK_START + 1, _last_tick)


func test_two_pump_close_in_time_then_only_one_tick() -> void:
	_timer.check_tick()
	_clock_time = TIME_START + (TIME_TICK / 2.0)
	_timer.check_tick()
	assert_eq(1, _callback_count)


func test_fast_pumping_only_tick_alternately() -> void:
	_timer.check_tick()
	_clock_time = TIME_START + (0.5 * TIME_TICK)
	_timer.check_tick()
	_callback_count = 0
	_clock_time = TIME_START + (1.0 * TIME_TICK)
	_timer.check_tick()
	assert_eq(1, _callback_count)
	assert_eq(TICK_START + 1, _last_tick)
	_callback_count = 0
	_clock_time = TIME_START + (1.5 * TIME_TICK)
	_timer.check_tick()
	assert_eq(0, _callback_count)


func test_slow_pump_multiple_ticks() -> void:
	_timer.check_tick()
	_clock_time = TIME_START + (3.0 * TIME_TICK)
	_callback_count = 0
	_timer.check_tick()
	assert_eq(3, _callback_count)


func test_paused_pump_then_no_ticks() -> void:
	_timer.check_tick()
	_callback_count = 0
	_timer.ticks_per_second = 0
	_clock_time = TIME_START + TIME_TICK
	_timer.check_tick()
	assert_eq(0, _callback_count)


func test_pause_pump_unpack_pump() -> void:
	_timer.check_tick()
	_timer.ticks_per_second = 0
	_clock_time = TIME_START + (1.0 * TIME_TICK)
	_timer.check_tick()
	_timer.ticks_per_second = TICK_PER_SEC
	_clock_time = TIME_START + (1.0 * TIME_TICK)
	_callback_count = 0
	_timer.check_tick()
	assert_eq(1, _callback_count)
	assert_eq(TICK_START + 1, _last_tick)


func test_pause_on_callback() -> void:
	var pause_timer := GameClock.new(TICK_START, false, func(): return _clock_time)
	pause_timer.ticks_per_second = TICK_PER_SEC
	pause_timer.add_call(func(_tid):
		pause_timer.ticks_per_second = 0
	)
	pause_timer.check_tick()
	_clock_time = TIME_START + (1.0 * TIME_TICK)
	_callback_count = 0
	pause_timer.check_tick()
	assert_eq(0, _callback_count)


func test_freeze_protection() -> void:
	var freeze_timer := GameClock.new(TICK_START, true, func(): return _clock_time)
	freeze_timer.ticks_per_second = TICK_PER_SEC
	var freeze_ticks: Array = []
	freeze_timer.add_call(func(tid): freeze_ticks.append(tid))
	freeze_timer.check_tick()
	freeze_ticks.clear()
	_clock_time = TIME_START + (1.01 * TIME_TICK) + GameClock.ACCEPTABLE_TICK_DELAY
	freeze_timer.check_tick()
	assert_true(freeze_ticks.size() >= 1)
	freeze_ticks.clear()
	_clock_time = TIME_START + (2.02 * TIME_TICK) + GameClock.DEFER_TICK_ON_DELAY_BY
	freeze_timer.check_tick()
	assert_eq(1, freeze_ticks.size())
	assert_eq(TICK_START + 2, freeze_ticks[0])


func test_pump_test_func_skip() -> void:
	_timer.add_test(func(_tid): return GameClock.TestResult.TEST_SKIP)
	_timer.check_tick()
	assert_eq(0, _callback_count)


func test_pump_test_func_pass() -> void:
	_timer.add_test(func(_tid): return GameClock.TestResult.TEST_PASS)
	_timer.check_tick()
	assert_eq(1, _callback_count)
