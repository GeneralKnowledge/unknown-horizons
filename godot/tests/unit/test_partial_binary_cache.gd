extends GutTest

var _terrain: Variant
var _bc: PartialBinaryBuildabilityCache


func before_each() -> void:
	var land := CoordSet.new()
	for x in range(10):
		for y in range(10):
			land.add(Vector2i(x, y))
	_terrain = {"land_or_coast": land}
	_bc = PartialBinaryBuildabilityCache.new(_terrain)


func _assert_set_eq(actual: CoordSet, expected: Array) -> void:
	var exp := CoordSet.new()
	for c in expected:
		exp.add(c if c is Vector2i else Vector2i(c[0], c[1]))
	assert_true(actual.equals_set(exp), "coord sets differ")


func test_horizontal_row2() -> void:
	_assert_set_eq(_bc._row2, [])
	_bc.add_area([Vector2i(2, 1)])
	_assert_set_eq(_bc._row2, [Vector2i(1, 1), Vector2i(2, 1)])
	_bc.add_area([Vector2i(3, 1)])
	_assert_set_eq(_bc._row2, [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
	_bc.add_area([Vector2i(1, 1)])
	_assert_set_eq(_bc._row2, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
	_bc.remove_area([Vector2i(2, 1)])
	_assert_set_eq(_bc._row2, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
	_bc.remove_area([Vector2i(1, 1)])
	_assert_set_eq(_bc._row2, [Vector2i(2, 1), Vector2i(3, 1)])
	_bc.remove_area([Vector2i(3, 1)])
	_assert_set_eq(_bc._row2, [])


func test_r2x2() -> void:
	var r2x2: CoordSet = _bc.cache[Vector2i(2, 2)]
	_assert_set_eq(r2x2, [])
	_bc.add_area([Vector2i(1, 1)])
	_bc.add_area([Vector2i(2, 1)])
	_bc.add_area([Vector2i(3, 2)])
	_bc.remove_area([Vector2i(2, 1)])
	_assert_set_eq(
		r2x2,
		[
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1), Vector2i(3, 2),
		]
	)
	_bc.remove_area([Vector2i(3, 2)])
	_bc.remove_area([Vector2i(1, 1)])
	_assert_set_eq(r2x2, [])


func test_r6x6() -> void:
	var r6x6: CoordSet = _bc.cache[Vector2i(6, 6)]
	_bc.add_area([Vector2i(7, 7)])
	_bc.add_area([Vector2i(8, 7)])
	_bc.remove_area([Vector2i(7, 7)])
	_bc.remove_area([Vector2i(8, 7)])
	_assert_set_eq(r6x6, [])
