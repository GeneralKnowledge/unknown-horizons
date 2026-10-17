class_name ParityTrace
extends RefCounted

## Build normalized parity traces (shared schema with development/godot/parity/trace_format.py).


static func res_name(res_id: int) -> String:
	for key in GameConstants.RES.keys():
		if int(GameConstants.RES[key]) == res_id:
			return key
	return str(res_id)


static func storage_named(inv: Inventory) -> Dictionary:
	var out: Dictionary = {}
	if inv == null:
		return out
	for res_id in inv.get_stored_resources().keys():
		var amount := int(inv.get_stored_resources()[res_id])
		if amount != 0:
			out[res_name(int(res_id))] = amount
	return out


static func from_session(session: GameSession, scenario_id: String) -> Dictionary:
	var buildings_out: Array = []
	for b in session.get_buildings_on_island(session.island):
		var stem := ContentLoader.stem_for_building_id(b.building_id)
		var inv: Inventory = b.get_storage()
		var producer: Producer = b.get_producer()
		var active: bool = producer.is_active() if producer != null else true
		buildings_out.append(
			{
				"stem": stem,
				"x": b.position.x,
				"y": b.position.y,
				"storage": storage_named(inv),
				"producer_active": active,
			}
		)
	return {
		"scenario_id": scenario_id,
		"engine": "godot",
		"tick": session.scheduler.cur_tick,
		"settlement_storage": storage_named(session.settlement.inventory),
		"buildings": buildings_out,
	}
