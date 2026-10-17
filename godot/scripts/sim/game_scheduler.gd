class_name GameScheduler
extends RefCounted

## Port of horizons/scheduler.py (single-player / test use).

const FIRST_TICK_ID := 0

var cur_tick: int = FIRST_TICK_ID - 1
var schedule: Dictionary = {} # tick -> Array
var additional_cur_tick_schedule: Array = []
var calls_by_instance: Dictionary = {} # instance -> Array
var timer: GameTimer


func _init(p_timer: GameTimer) -> void:
	timer = p_timer
	timer.add_call(_on_timer_tick)


func end() -> void:
	schedule.clear()
	if timer != null:
		timer.remove_call(_on_timer_tick)
	timer = null


func _on_timer_tick(tick_id: int) -> void:
	tick(tick_id)


func can_tick(tick_id: int) -> bool:
	return tick_id == cur_tick + 1


func tick(tick_id: int) -> void:
	assert(can_tick(tick_id))
	cur_tick = tick_id

	if schedule.has(cur_tick):
		var cur_schedule: Array = schedule[cur_tick]
		while cur_schedule.size() > 0:
			var cb: SchedulerCallback = cur_schedule.pop_front()
			if cb.invalid:
				continue
			cb.callback.call()
			if cb.loops != 0:
				_add_object(cb, true)
			else:
				if calls_by_instance.has(cb.class_instance):
					if cb.finish_callback.is_valid():
						cb.finish_callback.call()
					var lst: Array = calls_by_instance[cb.class_instance]
					lst.erase(cb)
					if lst.is_empty():
						calls_by_instance.erase(cb.class_instance)
		schedule.erase(cur_tick)

	_run_additional_jobs()

	if not schedule.is_empty():
		var keys := schedule.keys()
		keys.sort()
		assert(keys[0] > cur_tick)


func before_ticking() -> void:
	_run_additional_jobs()


func _run_additional_jobs() -> void:
	while not additional_cur_tick_schedule.is_empty():
		var batch: Array = additional_cur_tick_schedule.duplicate()
		additional_cur_tick_schedule.clear()
		for cb in batch:
			assert(cb.loops == 0)
			cb.callback.call()


func add_new_object(
	callback: Callable,
	class_instance: Variant,
	run_in: int = 1,
	loops: int = 1,
	loop_interval: int = -1,
	finish_callback: Callable = Callable()
) -> void:
	var cb := SchedulerCallback.new(
		self, callback, class_instance, run_in, loops,
		loop_interval if loop_interval > 0 else run_in,
		finish_callback
	)
	_add_object(cb, false)


func _add_object(callback_obj: SchedulerCallback, readd: bool) -> void:
	if callback_obj.loops > 0:
		callback_obj.loops -= 1
	if callback_obj.run_in == 0:
		additional_cur_tick_schedule.append(callback_obj)
	else:
		var interval: int = callback_obj.loop_interval if readd else callback_obj.run_in
		var tick_key: int = cur_tick + interval
		if not schedule.has(tick_key):
			schedule[tick_key] = []
		callback_obj.tick = tick_key
		schedule[tick_key].append(callback_obj)
		if not readd:
			if not calls_by_instance.has(callback_obj.class_instance):
				calls_by_instance[callback_obj.class_instance] = []
			calls_by_instance[callback_obj.class_instance].append(callback_obj)


func rem_object(callback_obj: SchedulerCallback) -> int:
	var removed := 0
	for key in schedule.keys():
		var lst: Array = schedule[key]
		while callback_obj in lst:
			lst.erase(callback_obj)
			if calls_by_instance.has(callback_obj.class_instance):
				calls_by_instance[callback_obj.class_instance].erase(callback_obj)
			removed += 1
	if calls_by_instance.has(callback_obj.class_instance):
		if calls_by_instance[callback_obj.class_instance].is_empty():
			calls_by_instance.erase(callback_obj.class_instance)
	return removed


func rem_all_classinst_calls(class_instance: Variant) -> void:
	if calls_by_instance.has(class_instance):
		for cb in calls_by_instance[class_instance]:
			cb.invalid = true
		calls_by_instance.erase(class_instance)
	additional_cur_tick_schedule = additional_cur_tick_schedule.filter(
		func(cb): return cb.class_instance != class_instance
	)


func rem_call(instance: Variant, callback: Callable) -> int:
	var removed := 0
	for key in schedule.keys():
		var lst: Array = schedule[key]
		for i in range(lst.size() - 1, -1, -1):
			var cb: SchedulerCallback = lst[i]
			if _same_scheduler_instance(cb.class_instance, instance) and cb.callback == callback and not cb.invalid:
				lst.remove_at(i)
				removed += 1
	if removed > 0 and calls_by_instance.has(instance):
		for i in range(calls_by_instance[instance].size() - 1, -1, -1):
			if calls_by_instance[instance][i].callback == callback:
				calls_by_instance[instance].remove_at(i)
		if calls_by_instance[instance].is_empty():
			calls_by_instance.erase(instance)
	for i in range(additional_cur_tick_schedule.size() - 1, -1, -1):
		var cb2: SchedulerCallback = additional_cur_tick_schedule[i]
		if _same_scheduler_instance(cb2.class_instance, instance) and cb2.callback == callback and not cb2.invalid:
			additional_cur_tick_schedule.remove_at(i)
			removed += 1
	return removed


func get_classinst_calls(instance: Variant, callback: Callable = Callable()) -> Dictionary:
	var calls := {}
	if calls_by_instance.has(instance):
		for cb in calls_by_instance[instance]:
			if not callback.is_valid() or cb.callback == callback:
				calls[cb] = cb.tick - cur_tick
	return calls


func get_remaining_ticks(instance: Variant, callback: Callable, assert_present: bool = true) -> Variant:
	var calls := get_classinst_calls(instance, callback)
	if assert_present:
		assert(calls.size() == 1)
		return calls.values()[0]
	if calls.is_empty():
		return null
	return calls.values()[0]


func get_ticks(seconds: float) -> int:
	return timer.get_ticks(seconds)


func get_ticks_of_month() -> int:
	return timer.get_ticks(GameTimer.INGAME_TICK_INTERVAL_SECONDS)


static func _same_scheduler_instance(a: Variant, b: Variant) -> bool:
	if a is Dictionary or b is Dictionary:
		return false
	return a == b


class SchedulerCallback extends RefCounted:
	var callback: Callable
	var class_instance: Variant
	var run_in: int
	var loops: int
	var loop_interval: int
	var finish_callback: Callable
	var tick: int = -1
	var invalid: bool = false

	func _init(
		_scheduler: Variant,
		p_callback: Callable,
		p_class_instance: Variant,
		p_run_in: int,
		p_loops: int,
		p_loop_interval: int,
		p_finish_callback: Callable = Callable()
	) -> void:
		assert(p_run_in >= 0)
		assert(p_loops > 0 or p_loops == -1)
		assert(p_callback.is_valid())
		assert(p_loop_interval >= 0)
		callback = p_callback
		class_instance = p_class_instance
		run_in = p_run_in
		loops = p_loops
		loop_interval = p_loop_interval if p_loop_interval > 0 else p_run_in
		finish_callback = p_finish_callback
