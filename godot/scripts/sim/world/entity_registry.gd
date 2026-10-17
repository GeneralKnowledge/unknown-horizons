class_name EntityRegistry
extends RefCounted

## Port of horizons/util/worldobject.py lookup (session-scoped).

var _objects: Dictionary = {}


func register(obj: Variant) -> void:
	if obj == null:
		return
	assert(obj.worldid != null)
	_objects[obj.worldid] = obj


func unregister(worldid: int) -> void:
	_objects.erase(worldid)


func get_by_id(worldid: int) -> Variant:
	if not _objects.has(worldid):
		return null
	return _objects[worldid]


func has_id(worldid: int) -> bool:
	return _objects.has(worldid)
