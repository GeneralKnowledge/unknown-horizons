extends SceneTree

## Headless helper: load legacy sqlite, run ticks, write inventory totals JSON.


func _initialize() -> void:
	var fixture := OS.get_environment("M7_FIXTURE")
	var out_path := OS.get_environment("M7_OUT")
	var ticks := int(OS.get_environment("M7_TICKS"))
	if fixture.is_empty() or out_path.is_empty() or ticks <= 0:
		push_error("Set M7_FIXTURE, M7_OUT, M7_TICKS")
		quit(1)
		return
	var session := SqliteSaveLoader.load(fixture)
	if session == null:
		push_error("load failed")
		quit(1)
		return
	session.run_ticks(ticks)
	var totals: Dictionary = {}
	for building in session.get_buildings_on_island(session.island):
		var inv: Inventory = building.get_storage()
		if inv == null:
			continue
		for res_id in inv.get_stored_resources().keys():
			var amount := int(inv.amount(int(res_id)))
			if amount == 0:
				continue
			var key := str(int(res_id))
			totals[key] = int(totals.get(key, 0)) + amount
	for res_id in session.settlement.inventory.get_stored_resources().keys():
		var amount := session.settlement.inventory.amount(int(res_id))
		if amount == 0:
			continue
		var key := str(int(res_id))
		totals[key] = int(totals.get(key, 0)) + amount
	var payload := {
		"fixture": fixture.get_file(),
		"ticks": ticks,
		"scheduler_tick": session.scheduler.cur_tick,
		"totals_by_resource_id": totals,
	}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write %s" % out_path)
		quit(1)
		return
	f.store_string(JSON.stringify(payload, "\t") + "\n")
	f.close()
	quit(0)
