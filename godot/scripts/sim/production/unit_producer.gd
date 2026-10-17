class_name UnitProducer
extends RefCounted

## Minimal barracks-style unit production into building storage.

var home_building: Building
var session: GameSession
var unit_resource_id: int = -1
var _tick_handle: int = -1


func _init(p_building: Building, p_session: GameSession, p_unit_res_id: int) -> void:
	home_building = p_building
	session = p_session
	unit_resource_id = p_unit_res_id
	session.scheduler.add_new_object(_on_tick, self, 16, -1, 16)


func _on_tick() -> void:
	if unit_resource_id < 0:
		return
	var storage := home_building.get_storage()
	if storage.amount(GameConstants.RES["SWORD"]) < 1:
		return
	if storage.get_free_space_for(unit_resource_id) <= 0:
		return
	storage.alter(GameConstants.RES["SWORD"], -1)
	storage.alter(unit_resource_id, 1)
