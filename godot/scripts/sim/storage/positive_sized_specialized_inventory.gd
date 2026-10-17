class_name PositiveSizedSpecializedInventory
extends SizedSpecializedInventory


func alter(res: int, delta: int) -> int:
	var subtractable := delta
	if delta < 0 and delta + amount(res) < 0:
		subtractable = -amount(res)
	return super.alter(res, subtractable)
