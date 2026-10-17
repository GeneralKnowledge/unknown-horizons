class_name TotalInventory
extends GlobalLimitInventory


func alter(res: int, amount: int) -> int:
	var overflow := maxi(0, amount + get_sum_of_stored_resources() - limit)
	return overflow + super.alter(res, amount - overflow)


func get_free_space_for(_res: int) -> int:
	return limit - get_sum_of_stored_resources()
