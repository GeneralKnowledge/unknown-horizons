class_name Producer
extends RefCounted

var production_lines: Dictionary = {}
var _productions: Dictionary = {}
var _inactive_productions: Dictionary = {}
var _scheduler: GameScheduler
var instance: Variant
var _active_flag: bool = true


func _init(p_instance: Variant, p_scheduler: GameScheduler, lines: Dictionary, auto_init: bool = true) -> void:
	instance = p_instance
	_scheduler = p_scheduler
	production_lines = lines
	if auto_init:
		for prod_line_id in production_lines.keys():
			var attrs: Dictionary = production_lines[prod_line_id]
			if attrs.get("enabled_by_default", true) == false:
				continue
			add_production(create_production(int(prod_line_id)))


func create_production(id: int, defer_listeners: bool = false) -> Production:
	var key_str := str(id)
	var data: Dictionary = production_lines[key_str] if production_lines.has(key_str) else production_lines[id]
	var storage: Inventory = instance.get_storage()
	return Production.new(
		_scheduler,
		storage,
		storage,
		id,
		data,
		false,
		defer_listeners
	)


func add_production(production: Production) -> void:
	var line_id := production.get_production_line_id()
	if production.is_paused():
		_inactive_productions[line_id] = production
	else:
		_productions[line_id] = production
	production.add_production_finished_listener(_on_production_finished)


func _on_production_finished(_production: Production) -> void:
	pass


func get_productions() -> Array:
	var all: Array = []
	all.append_array(_productions.values())
	all.append_array(_inactive_productions.values())
	return all


func get_production_lines() -> Array:
	var keys: Array = []
	keys.append_array(_productions.keys())
	keys.append_array(_inactive_productions.keys())
	return keys


func has_production_line(prod_line_id: int) -> bool:
	return _get_production(prod_line_id) != null


func _get_production(prod_line_id: int) -> Production:
	var key_str := str(prod_line_id)
	if _productions.has(prod_line_id):
		return _productions[prod_line_id]
	if _productions.has(key_str):
		return _productions[key_str]
	if _inactive_productions.has(prod_line_id):
		return _inactive_productions[prod_line_id]
	if _inactive_productions.has(key_str):
		return _inactive_productions[key_str]
	return null


func is_active(production: Production = null) -> bool:
	if production == null:
		for p in get_productions():
			if not p.is_paused():
				return true
		return false
	return not production.is_paused() and _productions.has(production.get_production_line_id())


func set_active(production: Production, active: bool) -> void:
	var line_id := production.get_production_line_id()
	if active:
		if not is_active(production):
			_productions[line_id] = production
			_inactive_productions.erase(line_id)
			production.pause(false)
	else:
		if is_active(production):
			_inactive_productions[line_id] = production
			_productions.erase(line_id)
			production.pause(true)


func toggle_active(production: Production = null) -> void:
	if production == null:
		for p in get_productions():
			toggle_active(p)
	else:
		set_active(production, not is_active(production))


func set_all_active(active: bool) -> void:
	for p in get_productions():
		set_active(p, active)


func finish_production_now() -> void:
	for p in get_productions():
		p.finish_production_now()


func ensure_production_line(prod_line_id: int) -> Production:
	var existing := _get_production(prod_line_id)
	if existing != null:
		return existing
	var key_str := str(prod_line_id)
	if not production_lines.has(key_str) and not production_lines.has(prod_line_id):
		return null
	var production := create_production(prod_line_id, true)
	add_production(production)
	return production


func sync_production_buckets() -> void:
	var all := get_productions()
	_productions.clear()
	_inactive_productions.clear()
	for production in all:
		var line_id: int = production.get_production_line_id()
		if production.is_paused() or production.get_state() in [
			ProductionStates.NONE,
			ProductionStates.DONE,
		]:
			_inactive_productions[line_id] = production
		else:
			_productions[line_id] = production


func _get_current_state() -> int:
	var current_state := ProductionStates.NONE
	for production in get_productions():
		var state: int = production.get_animating_state()
		if state >= 0 and current_state < state:
			current_state = state
	return current_state
