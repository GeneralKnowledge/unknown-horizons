class_name SpecializedInventory
extends Inventory


func alter(res: int, amount: int) -> int:
	if has_resource_slot(res):
		return super.alter(res, amount)
	return amount


func add_resource_slot(res: int) -> void:
	super.alter(res, 0)
	_changed()


func has_resource_slot(res: int) -> bool:
	return _storage.has(res)
