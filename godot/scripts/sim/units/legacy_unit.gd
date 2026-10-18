class_name LegacyUnit
extends RefCounted

## Placeholder for legacy units not fully simulated yet (ships, settlers, misc).

var worldid: int
var unit_type_id: int
var kind: String
var island: Island
var position: Vector2i
var owner: int = 0


func _init(
	p_worldid: int,
	p_unit_type_id: int,
	p_kind: String,
	p_island: Island,
	p_position: Vector2i,
	p_owner: int = 0
) -> void:
	worldid = p_worldid
	unit_type_id = p_unit_type_id
	kind = p_kind
	island = p_island
	position = p_position
	owner = p_owner
