extends GutTest

var _callback_called := false
var _timer: GameTimer
var _scheduler: GameScheduler


func before_each() -> void:
	_callback_called = false
	_timer = GameTimer.new()
	_scheduler = GameScheduler.new(_timer)


func after_each() -> void:
	if _scheduler != null:
		_scheduler.end()


func _cb() -> void:
	_callback_called = true


func test_create_then_register_with_timer() -> void:
	assert_true(_timer.has_call(_scheduler._on_timer_tick))


func test_end_then_unregister_from_timer() -> void:
	_scheduler.end()
	assert_false(_timer.has_call(_scheduler._on_timer_tick))


func test_multiple_sequential_ticks() -> void:
	_scheduler.before_ticking()
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_eq(GameScheduler.FIRST_TICK_ID, _scheduler.cur_tick)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_eq(GameScheduler.FIRST_TICK_ID + 1, _scheduler.cur_tick)


func test_fail_when_missing_start_tick() -> void:
	_scheduler.before_ticking()
	assert_false(_scheduler.can_tick(GameScheduler.FIRST_TICK_ID + 1))


func test_fail_when_same_tick_twice() -> void:
	_scheduler.before_ticking()
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_false(_scheduler.can_tick(GameScheduler.FIRST_TICK_ID))


func test_add_callback_before_first_tick() -> void:
	_scheduler.add_new_object(_cb, self, 0)
	_scheduler.before_ticking()
	assert_true(_callback_called)


func test_add_callback_run_in_1_on_first_tick() -> void:
	_scheduler.add_new_object(_cb, self, 1)
	_scheduler.before_ticking()
	assert_false(_callback_called)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_true(_callback_called)


func test_add_callback_only_triggered_once() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 2)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_false(_callback_called)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_true(_callback_called)
	_callback_called = false
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 2)
	assert_false(_callback_called)


func test_started_ticking_then_add_callback_for_next_tick() -> void:
	_scheduler.before_ticking()
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	_scheduler.add_new_object(_cb, self, 0)
	assert_false(_callback_called)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_true(_callback_called)


func test_started_ticking_then_add_callback_for_future() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 2)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_false(_callback_called)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_true(_callback_called)


func test_within_callback_add_new_callback_for_same_tick() -> void:
	_scheduler.before_ticking()
	var callback2_called := [false]
	var outer := func():
		_callback_called = true
		_scheduler.add_new_object(func(): callback2_called[0] = true, self, 0)
	_scheduler.add_new_object(outer, self, 1)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_true(callback2_called[0])


func test_within_callback_add_new_callback_for_future_tick() -> void:
	_scheduler.before_ticking()
	var callback2_called := [false]
	var outer := func():
		_callback_called = true
		_scheduler.add_new_object(func(): callback2_called[0] = true, self, 1)
	_scheduler.add_new_object(outer, self, 1)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_false(callback2_called[0])
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_true(callback2_called[0])


func test_add_periodic_callback_called_every_tick_3_times() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 1, 4)
	for i in range(GameScheduler.FIRST_TICK_ID, 4):
		_scheduler.tick(i)
		assert_true(_callback_called)
		_callback_called = false
	_scheduler.tick(4)
	assert_false(_callback_called)


func test_add_periodic_callback_run_every_other_tick_3_times() -> void:
	_scheduler.before_ticking()
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	_scheduler.add_new_object(_cb, self, 1, 3, 2)
	for i in range(GameScheduler.FIRST_TICK_ID + 1, 7):
		_scheduler.tick(i)
		if (i % 2 - 1) == 0:
			assert_true(_callback_called)
			_callback_called = false
		else:
			assert_false(_callback_called)
	_scheduler.tick(7)
	assert_false(_callback_called)


func test_remove_call_from_instance() -> void:
	_scheduler.before_ticking()
	var other := {}
	_scheduler.add_new_object(_cb, self, 1)
	_scheduler.add_new_object(_cb, other, 1)
	_scheduler.rem_call(self, _cb)
	_callback_called = false
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_true(_callback_called)


func test_remove_all_classinst_calls() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 1)
	_scheduler.add_new_object(_cb, self, 1)
	_scheduler.rem_all_classinst_calls(self)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_false(_callback_called)


func test_get_remaining_ticks() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 2)
	assert_eq(2, _scheduler.get_remaining_ticks(self, _cb))
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_eq(1, _scheduler.get_remaining_ticks(self, _cb))


func test_get_remaining_tick_periodic_callback() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 1, 2, 3)
	assert_eq(1, _scheduler.get_remaining_ticks(self, _cb))
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_eq(3, _scheduler.get_remaining_ticks(self, _cb))
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_eq(2, _scheduler.get_remaining_ticks(self, _cb))
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 2)
	assert_eq(1, _scheduler.get_remaining_ticks(self, _cb))


func test_get_ticks_of_month() -> void:
	assert_eq(_timer.get_ticks(30.0), _scheduler.get_ticks_of_month())
