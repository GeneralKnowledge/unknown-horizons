extends GutTest


func test_generic_alter() -> void:
	var s := Inventory.new()
	assert_eq(0, s.alter(1, 5))
	assert_eq(0, s.alter(2, 3))
	assert_eq(5, s.amount(1))
	assert_eq(3, s.amount(2))
	assert_eq(0, s.alter(1, 10))
	assert_eq(15, s.amount(1))


func test_reset() -> void:
	var s := Inventory.new()
	s.alter(1, 5)
	s.alter(2, 3)
	s.reset(1)
	assert_eq(0, s.amount(1))
	assert_eq(3, s.amount(2))


func test_reset_all() -> void:
	var s := Inventory.new()
	s.alter(1, 5)
	s.alter(2, 3)
	s.reset_all()
	assert_eq(0, s.amount(1))
	assert_eq(0, s.amount(2))


func test_limit() -> void:
	var s := Inventory.new()
	assert_eq(9223372036854775807, s.get_limit())
	assert_eq(9223372036854775807, s.get_limit(1))


func test_sum_of_stored_resources() -> void:
	var s := Inventory.new()
	s.alter(1, 5)
	s.alter(2, 3)
	assert_eq(8, s.get_sum_of_stored_resources())


func test_get_item() -> void:
	var s := Inventory.new()
	s.alter(1, 5)
	assert_eq(5, s.amount(1))
	assert_eq(0, s.amount(2))


func test_positive_sized_specialized() -> void:
	var s := PositiveSizedSpecializedInventory.new({1: 10})
	assert_eq(0, s.alter(1, 3))
	assert_eq(3, s.amount(1))
	assert_eq(7, s.get_free_space_for(1))
	assert_eq(3, s.alter(1, 10))


func test_specialized() -> void:
	var s := SpecializedInventory.new()
	assert_eq(3, s.alter(1, 3))
	assert_eq(-3, s.alter(1, -3))
	assert_false(s.has_resource_slot(1))
	s.add_resource_slot(1)
	assert_true(s.has_resource_slot(1))
	assert_eq(0, s.alter(1, 3))
	assert_eq(0, s.alter(1, -3))


func test_sized_specialized() -> void:
	var s := SizedSpecializedInventory.new()
	assert_eq(3, s.alter(1, 3))
	assert_eq(-3, s.alter(1, -3))
	assert_eq(0, s.get_limit(1))
	s.add_resource_slot(1, 10)
	assert_eq(10, s.get_free_space_for(1))
	assert_eq(0, s.alter(1, 3))
	assert_eq(5, s.alter(1, 12))


func test_global_limit_adjust() -> void:
	var s := GlobalLimitInventory.new(10)
	assert_eq(10, s.get_limit())
	s.alter(1, 10)
	assert_eq(10, s.amount(1))
	s.adjust_limit(-5)
	assert_eq(5, s.get_limit())
	assert_eq(5, s.amount(1))
	s.adjust_limit(-10)
	assert_eq(0, s.get_limit())


func test_total_storage() -> void:
	var s := TotalInventory.new(10)
	assert_eq(10, s.get_free_space_for(1))
	assert_eq(0, s.alter(2, 2))
	assert_eq(8, s.get_free_space_for(1))
	assert_eq(2, s.alter(2, 10))


func test_positive_total_storage() -> void:
	var s := PositiveTotalInventory.new(10)
	assert_eq(-2, s.alter(1, -2))
	assert_eq(0, s.alter(1, 2))
	assert_eq(0, s.alter(1, -2))
	assert_eq(-1, s.alter(1, -1))
	assert_eq(0, s.alter(2, 2))
	assert_eq(2, s.alter(2, 10))


func test_positive_sized_slot() -> void:
	var s := PositiveSizedSlotInventory.new(10)
	assert_eq(0, s.alter(1, 6))
	assert_eq(2, s.alter(1, 6))
	assert_eq(-10, s.alter(1, -20))


func test_positive_sized_num_slot() -> void:
	var s := PositiveSizedNumSlotInventory.new(10, 3)
	assert_eq(0, s.alter(1, 10))
	assert_eq(2, s.alter(1, 2))
	assert_eq(0, s.alter(2, 0))
	assert_eq(0, s.alter(2, 5))
	assert_eq(0, s.alter(3, 5))
	assert_eq(1, s.alter(4, 1))
