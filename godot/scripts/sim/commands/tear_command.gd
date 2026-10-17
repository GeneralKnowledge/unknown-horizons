class_name TearCommand
extends SimCommand

var building: Building


func _init(p_building: Building) -> void:
	building = p_building


func execute(session: GameSession) -> Variant:
	if building == null:
		return false
	if building.collecting != null:
		for collector in building.collecting.collectors:
			session.scheduler.rem_all_classinst_calls(collector)
	building.island.release_tiles(building)
	if building.settlement != null:
		building.settlement.remove_building(building)
	session.registry.unregister(building.worldid)
	session._buildings.erase(building.worldid)
	building.producer = null
	building.collecting = null
	return true
