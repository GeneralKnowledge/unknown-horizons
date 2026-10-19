class_name FieldCollector
extends BuildingCollector

## Legacy collectors.FieldCollector — farm field pickup with shuffled job order.


func _job_list_order() -> int:
	return CollectorJobList.OrderBy.FEWEST_AVAILABLE


func _build_job_list(radius: int, home_size: Vector2i) -> CollectorJobList:
	var job_list := super._build_job_list(radius, home_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(home_building.worldid) + int(session.scheduler.cur_tick)
	job_list.sort_jobs(rng)
	return job_list
