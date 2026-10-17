class_name TearCommand
extends RefCounted

var building: Building


func _init(p_building: Building) -> void:
	building = p_building


func execute(session: GameSession) -> bool:
	if building == null:
		return false
	building.island.release_tiles(building)
	building.settlement.buildings.erase(building)
	session.registry.unregister(building.worldid)
	session._buildings.erase(building.worldid)
	building.producer = null
	return true
