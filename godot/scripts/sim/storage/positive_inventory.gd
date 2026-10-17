class_name PositiveInventory
extends Inventory


func alter(res: int, delta: int) -> int:
	var subtractable := delta
	if delta < 0 and delta + amount(res) < 0:
		subtractable = -amount(res)
	var ret := super.alter(res, subtractable)
	return (delta - subtractable) + ret
