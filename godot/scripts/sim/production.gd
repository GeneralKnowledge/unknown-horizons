class_name Production
extends ChangeListener

var prod_id: int
var inventory: Inventory
var owner_inventory: Inventory
var _prod_line: ProductionLine
var _state: int = ProductionStates.WAITING_FOR_RES
var _pause_remaining_ticks: int = 0
var _pause_old_state: int = -1
var _creation_tick: int = 0
var _scheduler: GameScheduler
var _finished_listeners: Array[Callable] = []


func _init(
	p_scheduler: GameScheduler,
	p_inventory: Inventory,
	p_owner_inventory: Inventory,
	p_prod_id: int,
	prod_data: Dictionary,
	start_finished: bool = false,
	defer_listeners: bool = false
) -> void:
	_scheduler = p_scheduler
	inventory = p_inventory
	owner_inventory = p_owner_inventory
	prod_id = p_prod_id
	_prod_line = ProductionLine.new(p_prod_id, prod_data)
	_creation_tick = _scheduler.cur_tick
	if start_finished:
		_give_produced_res()
	_state = ProductionStates.WAITING_FOR_RES
	if not defer_listeners:
		_add_listeners(true)


func get_production_line_id() -> int:
	return _prod_line.id


func get_state() -> int:
	return _state


## 0.0–1.0 while PRODUCING; -1 when not in a timed production tick.
func producing_progress() -> float:
	if _state != ProductionStates.PRODUCING:
		return -1.0
	var remaining := int(_scheduler.get_remaining_ticks(self, _finished_producing))
	var total := int(_scheduler.get_ticks(_prod_line.time))
	if total <= 0:
		return 0.0
	return clampf(1.0 - float(remaining) / float(total), 0.0, 1.0)


func get_animating_state() -> int:
	if _prod_line.changes_animation:
		return _state
	return -1


func is_paused() -> bool:
	return _state == ProductionStates.PAUSED


func add_production_finished_listener(listener: Callable) -> void:
	_finished_listeners.append(listener)


func on_production_finished() -> void:
	for listener in _finished_listeners:
		listener.call(self)
	production_finished.emit()


signal production_finished


func pause(do_pause: bool = true) -> void:
	if not do_pause:
		_state = _pause_old_state
		_pause_old_state = -1
		if _state in [ProductionStates.WAITING_FOR_RES, ProductionStates.INVENTORY_FULL, ProductionStates.DONE]:
			_add_listeners(true)
		elif _state == ProductionStates.PRODUCING:
			_scheduler.add_new_object(_finished_producing, self, _pause_remaining_ticks)
	else:
		_pause_old_state = _state
		_state = ProductionStates.PAUSED
		if _pause_old_state in [ProductionStates.WAITING_FOR_RES, ProductionStates.INVENTORY_FULL, ProductionStates.DONE]:
			_remove_listeners()
		elif _pause_old_state == ProductionStates.PRODUCING:
			_pause_remaining_ticks = int(_scheduler.get_remaining_ticks(self, _finished_producing))
			_scheduler.rem_call(self, _finished_producing)
	_changed()


func _get_producing_callback() -> Callable:
	return _finished_producing


func _check_inventory() -> void:
	if not _check_for_space_for_produced_res():
		_state = ProductionStates.INVENTORY_FULL
		_changed()
	elif _check_available_res():
		_remove_listeners()
		_start_production()
	else:
		_state = ProductionStates.WAITING_FOR_RES
		_changed()


func _start_production() -> void:
	_state = ProductionStates.PRODUCING
	_produce()
	_changed()


func _produce() -> void:
	assert(_check_available_res())
	assert(_check_for_space_for_produced_res())
	_remove_res_to_expend()
	var time_ticks := _scheduler.get_ticks(_prod_line.time)
	_scheduler.add_new_object(_finished_producing, self, time_ticks)


func _finished_producing() -> void:
	_give_produced_res()
	on_production_finished()
	_state = ProductionStates.WAITING_FOR_RES
	_add_listeners(true)


func _add_listeners(check_now: bool = false) -> void:
	inventory.add_change_listener(_check_inventory)
	if check_now:
		_check_inventory()


func _remove_listeners() -> void:
	inventory.discard_change_listener(_check_inventory)


func _give_produced_res() -> void:
	for res in _prod_line.produced_res.keys():
		inventory.alter(int(res), int(_prod_line.produced_res[res]))


func _check_available_res() -> bool:
	for res in _prod_line.consumed_res.keys():
		if inventory.amount(int(res)) < -int(_prod_line.consumed_res[res]):
			return false
	return true


func _remove_res_to_expend() -> void:
	for res in _prod_line.consumed_res.keys():
		var remnant := inventory.alter(int(res), int(_prod_line.consumed_res[res]))
		assert(remnant == 0)


func _check_for_space_for_produced_res() -> bool:
	for res in _prod_line.produced_res.keys():
		if inventory.get_free_space_for(int(res)) < int(_prod_line.produced_res[res]):
			return false
	return true


func finish_production_now() -> void:
	_remove_listeners()
	_give_produced_res()
	on_production_finished()
	_state = ProductionStates.WAITING_FOR_RES
	_add_listeners(true)


## Restore mid-game state from legacy SQLite `production` table (after storage rows applied).
func restore_from_legacy_save(
	state_index: int,
	remaining_ticks: int,
	pause_old_state_index: int,
	creation_tick: int
) -> void:
	_remove_listeners()
	_scheduler.rem_call(self, _finished_producing)
	_creation_tick = creation_tick
	_pause_old_state = pause_old_state_index
	_state = state_index
	if _state == ProductionStates.PAUSED:
		_pause_remaining_ticks = remaining_ticks
		if _pause_old_state < 0:
			_pause_old_state = ProductionStates.WAITING_FOR_RES
	elif _state == ProductionStates.PRODUCING:
		_scheduler.add_new_object(_finished_producing, self, remaining_ticks)
	elif _state in [ProductionStates.WAITING_FOR_RES, ProductionStates.INVENTORY_FULL]:
		_add_listeners(false)
	elif _state in [ProductionStates.NONE, ProductionStates.DONE]:
		pass
	_changed()
