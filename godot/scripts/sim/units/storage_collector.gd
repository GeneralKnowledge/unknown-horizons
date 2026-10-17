class_name StorageCollector
extends BuildingCollector

## Warehouse logistics — horizons StorageCollector (FOR_STORAGE_COLLECTOR ordering).


func _build_job_list(radius: int, home_size: Vector2i) -> CollectorJobList:
	var job_list := CollectorJobList.new(self, CollectorJobList.OrderBy.FOR_STORAGE_COLLECTOR)
	var home_inv := get_home_inventory()
	for building in _source_buildings():
		if building == home_building:
			continue
		if building.settlement != home_building.settlement:
			continue
		for res_name in GameConstants.RES:
			var rid := int(GameConstants.RES[res_name])
			if _reserved_for_active_production(building, rid):
				continue
			if building.get_storage().get_free_space_for(rid) > 0:
				continue
			var available: int = building.get_storage().amount(rid)
			if available <= 0:
				continue
			if home_inv.get_free_space_for(rid) <= 0:
				continue
			var dist := _distance_rect_to_point(home_building.position, home_size, building.position)
			if dist > float(radius):
				continue
			var job := CollectorJob.new(building, [rid], available)
			if building.get_storage().get_free_space_for(rid) == 0:
				job.target_inventory_full_num = 1
			job_list.append_job(job)
	return job_list


func _reserved_for_active_production(building: Building, res_id: int) -> bool:
	var producer := building.get_producer()
	if producer == null:
		return false
	for production in producer.get_productions():
		if production.is_paused():
			continue
		for res_key in production._prod_line.consumed_res.keys():
			if int(res_key) != res_id:
				continue
			if int(production._prod_line.consumed_res[res_key]) < 0:
				return true
	return false


func get_home_inventory() -> Inventory:
	if home_building.building_id == GameConstants.BUILDINGS["WAREHOUSE"]:
		return home_building.settlement.inventory
	return super.get_home_inventory()
