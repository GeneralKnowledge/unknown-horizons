class_name PositiveSizedNumSlotInventory
extends PositiveSizedSlotInventory

var slotnum: int = 0


func _init(p_limit: int = 0, p_slotnum: int = 0) -> void:
	super._init(p_limit)
	slotnum = p_slotnum


func alter(res: int, amount: int) -> int:
	if amount == 0:
		return 0
	if not _storage.has(res) and _storage.size() >= slotnum:
		return amount
	return super.alter(res, amount)


func get_free_space_for(res: int) -> int:
	if not _storage.has(res) and _storage.size() >= slotnum:
		return 0
	return super.get_free_space_for(res)
