class_name PositiveSizedSlotInventory
extends PositiveInventory

var slot_limit: int = 0


func _init(p_limit: int = 0) -> void:
	slot_limit = p_limit


func get_limit(_res: int = -1) -> int:
	return slot_limit


func alter(res: int, amount: int) -> int:
	var check := maxi(0, amount + amount(res) - slot_limit)
	var ret := super.alter(res, amount - check)
	if amount(res) == 0:
		_storage.erase(res)
	return check + ret
