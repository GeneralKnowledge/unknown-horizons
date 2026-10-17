extends GutTest

var _callback_called := false
var _timer: GameTimer
var _scheduler: GameScheduler


func before_each() -> void:
	_callback_called = false
	_timer = GameTimer.new()
	_scheduler = GameScheduler.new(_timer)


func after_each() -> void:
	_scheduler.end()


func _cb() -> void:
	_callback_called = true


func test_multiple_sequential_ticks() -> void:
	_scheduler.before_ticking()
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_eq(GameScheduler.FIRST_TICK_ID, _scheduler.cur_tick)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID + 1)
	assert_eq(GameScheduler.FIRST_TICK_ID + 1, _scheduler.cur_tick)


func test_add_callback_run_in_1_on_first_tick() -> void:
	_scheduler.add_new_object(_cb, self, 1)
	_scheduler.before_ticking()
	assert_false(_callback_called)
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_true(_callback_called)


func test_add_periodic_callback_called_every_tick_3_times() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 1, 4)
	for i in range(GameScheduler.FIRST_TICK_ID, 4):
		_scheduler.tick(i)
		assert_true(_callback_called)
		_callback_called = false
	_scheduler.tick(4)
	assert_false(_callback_called)


func test_get_remaining_ticks() -> void:
	_scheduler.before_ticking()
	_scheduler.add_new_object(_cb, self, 2)
	assert_eq(2, _scheduler.get_remaining_ticks(self, _cb))
	_scheduler.tick(GameScheduler.FIRST_TICK_ID)
	assert_eq(1, _scheduler.get_remaining_ticks(self, _cb))
