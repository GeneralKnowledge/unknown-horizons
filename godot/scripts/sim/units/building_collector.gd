class_name BuildingCollector
extends RefCounted

const WORK_DURATION_TICKS := 16
const USE_PATHFINDING_E2 := true
const TICKS_PER_PATH_STEP := 2

var home_building: Building
var session: GameSession
var unit_type_id: int
var legacy_unit_worldid: int = -1
var _state := "idle"
var _active_job: CollectorJob


func _init(p_home: Building, p_session: GameSession, p_unit_type: int) -> void:
	home_building = p_home
	session = p_session
	unit_type_id = p_unit_type
	session.scheduler.add_new_object(_on_work_tick, self, 1, -1, 1)


func _on_work_tick() -> void:
	search_job()


func search_job() -> void:
	if _state == "working" or _state == "moving":
		return
	if _deposit_legacy_job_cargo_if_any():
		return
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(home_building.building_id)
	)
	var radius := int(export.get("radius", 3))
	var home_size := Vector2i(int(export.get("size_x", 1)), int(export.get("size_y", 1)))
	var job_list := _build_job_list(radius, home_size)
	if job_list.jobs.is_empty():
		return
	job_list.sort_jobs()
	var job: CollectorJob = job_list.jobs[0]
	_active_job = job
	var travel_ticks := _travel_ticks_to_job(job)
	if travel_ticks > 0:
		_state = "moving"
		session.scheduler.add_new_object(_begin_work_after_travel, self, travel_ticks)
	else:
		_state = "working"
		session.scheduler.add_new_object(_finish_active_job, self, WORK_DURATION_TICKS)


func _begin_work_after_travel() -> void:
	_state = "working"
	session.scheduler.add_new_object(_finish_active_job, self, WORK_DURATION_TICKS)


func _travel_ticks_to_job(job: CollectorJob) -> int:
	if not USE_PATHFINDING_E2:
		return 0
	var target: Vector2i = job.target.position
	var path := IslandPathfinder.find_path(home_building.island, home_building.position, target)
	if path.is_empty():
		return 0
	return maxi(0, (path.size() - 1) * TICKS_PER_PATH_STEP)


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


func _source_buildings() -> Array:
	return session.get_buildings_on_island(home_building.island)


func _build_job_list(radius: int, home_size: Vector2i) -> CollectorJobList:
	var job_list := CollectorJobList.new(self, CollectorJobList.OrderBy.FEWEST_AVAILABLE_AND_DISTANCE)
	var collect_res: Array = _resources_to_collect()
	if collect_res.is_empty():
		return job_list
	for building in _source_buildings():
		if building == home_building:
			continue
		for res_id in collect_res:
			var available: int = building.get_storage().amount(int(res_id))
			if available <= 0:
				continue
			var dist := _distance_rect_to_point(home_building.position, home_size, building.position)
			if dist > float(radius):
				continue
			job_list.append_job(CollectorJob.new(building, [int(res_id)], available))
	return job_list


func _finish_active_job() -> void:
	if _active_job == null:
		push_warning("BuildingCollector._finish_active_job without active job")
		_state = "idle"
		return
	_finish_job(_active_job)
	_active_job = null


func _finish_job(job: CollectorJob) -> void:
	if job.resources.is_empty():
		_state = "idle"
		return
	var res_id := int(job.resources[0])
	var amount := mini(job.available, job.target.get_storage().amount(res_id))
	if amount > 0:
		job.target.get_storage().alter(res_id, -amount)
		get_home_inventory().alter(res_id, amount)
	_state = "idle"


## Apply in-flight goods from legacy `collector_job` at load (no path replay).
## Legacy stores carried amounts on the job row, not in home or target building storage.
func apply_legacy_job_at_load(target: Building, res_id: int, amount: int) -> bool:
	if amount <= 0 or res_id < 0:
		return false
	var cargo: Dictionary = get_meta("legacy_job_cargo") if has_meta("legacy_job_cargo") else {}
	cargo[int(res_id)] = int(cargo.get(res_id, 0)) + amount
	set_meta("legacy_job_cargo", cargo)
	if target != null:
		set_meta("legacy_job_target_worldid", int(target.worldid))
	return true


## Deliver in-flight legacy cargo into the home building (first idle collector tick).
func _deposit_legacy_job_cargo_if_any() -> bool:
	if not has_meta("legacy_job_cargo"):
		return false
	var cargo: Dictionary = get_meta("legacy_job_cargo")
	if cargo.is_empty():
		_clear_legacy_job_cargo_meta()
		return false
	var home_inv := get_home_inventory()
	var any_moved := false
	var remaining: Dictionary = {}
	for res_key in cargo.keys():
		var res_id := int(res_key)
		var amount := int(cargo[res_key])
		if amount <= 0:
			continue
		var free := home_inv.get_free_space_for(res_id)
		if free <= 0:
			remaining[res_id] = amount
			continue
		var moved := mini(amount, free)
		home_inv.alter(res_id, moved)
		any_moved = true
		var left := amount - moved
		if left > 0:
			remaining[res_id] = left
	if remaining.is_empty():
		_clear_legacy_job_cargo_meta()
	else:
		set_meta("legacy_job_cargo", remaining)
	return any_moved


func _clear_legacy_job_cargo_meta() -> void:
	if has_meta("legacy_job_cargo"):
		remove_meta("legacy_job_cargo")
	if has_meta("legacy_job_target_worldid"):
		remove_meta("legacy_job_target_worldid")


func legacy_job_cargo_amount() -> int:
	if not has_meta("legacy_job_cargo"):
		return 0
	var total := 0
	for v in get_meta("legacy_job_cargo").values():
		total += int(v)
	return total


func _distance_rect_to_point(origin: Vector2i, size: Vector2i, point: Vector2i) -> float:
	# Origin is top-right (see BuildFootprint.origin_tiles).
	var left := origin.x - (size.x - 1)
	var top := origin.y - (size.y - 1)
	var right := origin.x
	var bottom := origin.y
	var dx := 0
	var t := left - point.x
	if t > dx:
		dx = t
	t = point.x - right
	if t > dx:
		dx = t
	var dy := 0
	t = top - point.y
	if t > dy:
		dy = t
	t = point.y - bottom
	if t > dy:
		dy = t
	return sqrt(float(dx * dx + dy * dy))


func get_home_inventory() -> Inventory:
	return home_building.get_storage()


var position: SimPoint:
	get:
		return SimPoint.new(home_building.position.x, home_building.position.y)
