extends GutTest

class DummyCollector:
	var position: SimPoint
	var _inventory: Inventory

	func _init(x: int, y: int) -> void:
		position = SimPoint.new(x, y)
		_inventory = Inventory.new()
		_inventory.alter(1, 3)
		_inventory.alter(2, 1)
		_inventory.alter(3, 2)

	func get_home_inventory() -> Inventory:
		return _inventory


class DummyObject:
	var id: int
	var loading_area: SimPoint

	func _init(p_id: int, x: int, y: int) -> void:
		id = p_id
		loading_area = SimPoint.new(x, y)


class DummyJob:
	var object: DummyObject
	var resources: Array
	var target_inventory_full_num: int = 0

	func _init(p_object: DummyObject, res_entries: Array) -> void:
		object = p_object
		resources = []
		for e in res_entries:
			resources.append(e["res"])


func _make_list(order: int) -> CollectorJobList:
	var collector := DummyCollector.new(0, 0)
	var job_list := CollectorJobList.new(collector, order)
	job_list.append_job(DummyJob.new(DummyObject.new(1, 3, 3), [{"res": 3}]))
	job_list.append_job(DummyJob.new(DummyObject.new(2, 1, 1), [{"res": 1}]))
	job_list.append_job(DummyJob.new(DummyObject.new(3, 2, 2), [{"res": 2}]))
	return job_list


func test_sort_distance() -> void:
	var job_list := _make_list(CollectorJobList.OrderBy.DISTANCE)
	job_list.sort_jobs()
	assert_eq(2, job_list.jobs[0].object.id)
	assert_eq(3, job_list.jobs[1].object.id)
	assert_eq(1, job_list.jobs[2].object.id)


func test_sort_fewest_available() -> void:
	var job_list := _make_list(CollectorJobList.OrderBy.FEWEST_AVAILABLE)
	job_list.sort_jobs(null)
	assert_eq(3, job_list.jobs[0].object.id)
	assert_eq(1, job_list.jobs[1].object.id)
	assert_eq(2, job_list.jobs[2].object.id)


func test_sort_fewest_available_and_distance() -> void:
	var collector := DummyCollector.new(0, 0)
	var job_list := CollectorJobList.new(collector, CollectorJobList.OrderBy.FEWEST_AVAILABLE_AND_DISTANCE)
	job_list.append_job(DummyJob.new(DummyObject.new(1, 3, 3), [{"res": 2}]))
	job_list.append_job(DummyJob.new(DummyObject.new(2, 1, 1), [{"res": 1}]))
	job_list.append_job(DummyJob.new(DummyObject.new(3, 2, 2), [{"res": 2}]))
	job_list.sort_jobs()
	assert_eq(2, job_list.jobs[0].object.id)
	assert_eq(3, job_list.jobs[1].object.id)
	assert_eq(1, job_list.jobs[2].object.id)


func test_sort_for_storage_collector() -> void:
	var collector := DummyCollector.new(0, 0)
	var job_list := CollectorJobList.new(collector, CollectorJobList.OrderBy.FOR_STORAGE_COLLECTOR)
	job_list.append_job(DummyJob.new(DummyObject.new(1, 3, 3), [{"res": 2}]))
	job_list.append_job(DummyJob.new(DummyObject.new(2, 1, 1), [{"res": 1}]))
	job_list.append_job(DummyJob.new(DummyObject.new(3, 2, 2), [{"res": 2}]))
	var full_job := DummyJob.new(DummyObject.new(4, 9, 0), [{"res": 4}])
	full_job.target_inventory_full_num = 1
	job_list.append_job(full_job)
	job_list.sort_jobs()
	assert_eq(4, job_list.jobs[0].object.id)
