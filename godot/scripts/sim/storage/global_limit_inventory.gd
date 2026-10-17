class_name GlobalLimitInventory
extends Inventory

var limit: int = 0


func _init(p_limit: int = 0) -> void:
	limit = p_limit


func adjust_limit(delta: int) -> void:
	limit += delta
	if limit < 0:
		limit = 0
	for res in _storage.keys():
		if int(_storage[res]) > limit:
			_storage[res] = limit
	_changed()


func get_limit(_res: int = -1) -> int:
	return limit
