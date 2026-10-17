extends GutTest


func test_generic_alter() -> void:
	var s := Inventory.new()
	assert_eq(0, s.alter(1, 5))
	assert_eq(0, s.alter(2, 3))
	assert_eq(5, s.amount(1))
	assert_eq(3, s.amount(2))


func test_positive_sized_specialized() -> void:
	var s := PositiveSizedSpecializedInventory.new({1: 10})
	assert_eq(0, s.alter(1, 3))
	assert_eq(3, s.amount(1))
	assert_eq(7, s.get_free_space_for(1))
	assert_eq(3, s.alter(1, 10)) # 7 fits, 3 returned
