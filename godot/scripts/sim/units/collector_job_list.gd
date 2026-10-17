class_name CollectorJobList
extends RefCounted

## Subset of horizons/world/units/collectors/collector.py JobList sorting.

enum OrderBy {
	DISTANCE,
	FEWEST_AVAILABLE,
	FEWEST_AVAILABLE_AND_DISTANCE,
	FOR_STORAGE_COLLECTOR,
}

var jobs: Array = []
var collector: Variant
var _order: int


func _init(p_collector: Variant, order: int) -> void:
	collector = p_collector
	_order = order


func append_job(job: Variant) -> void:
	jobs.append(job)


func sort_jobs(shuffle_rng: RandomNumberGenerator = null) -> void:
	match _order:
		OrderBy.DISTANCE:
			_sort_jobs_distance()
		OrderBy.FEWEST_AVAILABLE:
			_sort_jobs_fewest_available(shuffle_rng, true)
		OrderBy.FEWEST_AVAILABLE_AND_DISTANCE:
			_sort_jobs_fewest_available_and_distance()
		OrderBy.FOR_STORAGE_COLLECTOR:
			_sort_jobs_for_storage_collector()


func _sort_jobs_distance() -> void:
	var collector_point: SimPoint = collector.position
	jobs.sort_custom(func(a, b):
		return collector_point.distance_to(a.object.loading_area) < collector_point.distance_to(b.object.loading_area)
	)


func _sort_jobs_fewest_available(rng: RandomNumberGenerator, shuffle_first: bool) -> void:
	if shuffle_first and rng != null:
		jobs.shuffle()
	var inventory: Inventory = collector.get_home_inventory()
	jobs.sort_custom(func(a, b):
		return _min_inventory_for_job(inventory, a) < _min_inventory_for_job(inventory, b)
	)


func _sort_jobs_fewest_available_and_distance() -> void:
	var inventory: Inventory = collector.get_home_inventory()
	var collector_point: SimPoint = collector.position
	jobs.sort_custom(func(a, b):
		var da := collector_point.distance_to(a.object.loading_area)
		var db := collector_point.distance_to(b.object.loading_area)
		if da != db:
			return da < db
		return _min_inventory_for_job(inventory, a) < _min_inventory_for_job(inventory, b)
	)


func _sort_jobs_for_storage_collector() -> void:
	var inventory: Inventory = collector.get_home_inventory()
	var collector_point: SimPoint = collector.position
	jobs.sort_custom(func(a, b):
		if a.target_inventory_full_num != b.target_inventory_full_num:
			return a.target_inventory_full_num > b.target_inventory_full_num
		var da := collector_point.distance_to(a.object.loading_area)
		var db := collector_point.distance_to(b.object.loading_area)
		if da != db:
			return da < db
		return _min_inventory_for_job(inventory, a) < _min_inventory_for_job(inventory, b)
	)


static func _min_inventory_for_job(inventory: Inventory, job: Variant) -> int:
	var minimum := 2147483647
	for res in job.resources:
		minimum = mini(minimum, inventory.amount(int(res)))
	return minimum
