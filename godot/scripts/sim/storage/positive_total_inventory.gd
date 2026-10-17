class_name PositiveTotalInventory
extends TotalInventory


func alter(res: int, amount: int) -> int:
	var subtractable := amount
	if amount < 0 and amount + amount(res) < 0:
		subtractable = -amount(res)
	var leftover := amount - subtractable
	var ret := super.alter(res, subtractable)
	if amount(res) == 0:
		_storage.erase(res)
	return leftover + ret
