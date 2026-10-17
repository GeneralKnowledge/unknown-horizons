class_name BuildingCollector
extends RefCounted

const WORK_DURATION_TICKS := 16

var home_building: Building
var session: GameSession
var unit_type_id: int
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
	if _state == "working":
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
	_state = "working"
	_active_job = job
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
		home_building.get_storage().alter(res_id, amount)
	_state = "idle"


func _distance_rect_to_point(origin: Vector2i, size: Vector2i, point: Vector2i) -> float:
	var left := origin.x
	var top := origin.y
	var right := origin.x + size.x - 1
	var bottom := origin.y + size.y - 1
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
