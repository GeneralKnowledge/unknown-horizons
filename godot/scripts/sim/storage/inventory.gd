class_name Inventory
extends ChangeListener

## Port of horizons/world/storage.py (subset used in PoC).

var _storage: Dictionary = {}


func alter(res: int, amount: int) -> int:
	_storage[res] = int(_storage.get(res, 0)) + amount
	_changed()
	return 0


func reset(res: int) -> void:
	if _storage.has(res):
		_storage[res] = 0
		_changed()


func reset_all() -> void:
	for res in _storage.keys():
		_storage[res] = 0
	_changed()


func get_limit(_res: int = -1) -> int:
	return 9223372036854775807


func get_free_space_for(res: int) -> int:
	return get_limit(res) - amount(res)


func get_sum_of_stored_resources() -> int:
	var total := 0
	for v in _storage.values():
		total += int(v)
	return total


func amount(res: int) -> int:
	return int(_storage.get(res, 0))
