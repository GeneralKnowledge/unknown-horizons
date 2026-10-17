class_name CoordSet
extends RefCounted

var _coords: Dictionary = {}


func clear() -> void:
	_coords.clear()


func has(v: Vector2i) -> bool:
	return _coords.has(v)


func add(v: Vector2i) -> void:
	_coords[v] = true


func discard(v: Vector2i) -> void:
	_coords.erase(v)


func size() -> int:
	return _coords.size()


func keys() -> Array:
	return _coords.keys()


func duplicate_set() -> CoordSet:
	var other := CoordSet.new()
	for k in _coords.keys():
		other.add(k)
	return other


func equals_set(other: CoordSet) -> bool:
	if other == null or size() != other.size():
		return false
	for k in _coords.keys():
		if not other.has(k):
			return false
	return true
