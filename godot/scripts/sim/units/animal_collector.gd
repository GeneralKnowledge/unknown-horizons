class_name AnimalCollector
extends RefCounted

const WORK_DURATION_TICKS := 16

var home_building: Building
var session: GameSession
var unit_type_id: int
var _state := "idle"
var _active_animal: WildAnimal


func _init(p_home: Building, p_session: GameSession, p_unit_type: int) -> void:
	home_building = p_home
	session = p_session
	unit_type_id = p_unit_type
	session.scheduler.add_new_object(_on_work_tick, self, 1, -1, 1)


func _on_work_tick() -> void:
	search_job()


func search_job() -> void:
	if _state == "working":
		return
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(home_building.building_id)
	)
	var radius := float(export.get("radius", 10))
	var collect_res: Array = _resources_to_collect()
	if collect_res.is_empty():
		return
	var best: WildAnimal = null
	var best_dist := radius + 1.0
	for animal in session.get_wild_animals_on_island(home_building.island):
		for res_id in collect_res:
			if animal.get_storage().amount(int(res_id)) <= 0:
				continue
			var dist := home_building.position.distance_to(animal.position)
			if dist <= radius and dist < best_dist:
				best_dist = dist
				best = animal
	if best == null:
		return
	_active_animal = best
	_state = "working"
	session.scheduler.add_new_object(_finish_active_job, self, WORK_DURATION_TICKS)


func _resources_to_collect() -> Array:
	var needed: Dictionary = {}
	var producer := home_building.get_producer()
	if producer == null:
		return []
	for production in producer.get_productions():
		for res_key in production._prod_line.consumed_res.keys():
			var res_id := int(res_key)
			if int(production._prod_line.consumed_res[res_key]) >= 0:
				continue
			if home_building.get_storage().get_free_space_for(res_id) > 0:
				needed[res_id] = true
	var out: Array = []
	for res_id in needed.keys():
		out.append(int(res_id))
	return out


func _finish_active_job() -> void:
	if _active_animal == null:
		_state = "idle"
		return
	var res_id := GameConstants.RES["DEER_MEAT"]
	var amount := mini(2, _active_animal.get_storage().amount(res_id))
	if amount > 0:
		_active_animal.get_storage().alter(res_id, -amount)
		get_home_inventory().alter(res_id, amount)
	_active_animal = null
	_state = "idle"


func get_home_inventory() -> Inventory:
	return home_building.get_storage()


var position: SimPoint:
	get:
		return SimPoint.new(home_building.position.x, home_building.position.y)
