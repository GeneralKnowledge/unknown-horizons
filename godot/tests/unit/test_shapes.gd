extends GutTest


func test_point() -> void:
	var p1 := SimPoint.new(0, 0)
	var p2 := SimPoint.new(0, 2)
	assert_eq(2.0, p1.distance_to(p2))
	assert_eq(1.0, p1.distance_to([0, 1]))
	assert_eq([[0, 0]], p1.get_coordinates())
	assert_true(p1.equals(p1.copy()))


func test_rect() -> void:
	var r1 := SimRect.new(SimPoint.new(0, 0), 1, 1)
	var r2 := SimRect.new(0, 0, 1, 1)
	var r3 := SimRect.new(SimPoint.new(2, 2), 1, 1)
	assert_true(r1.equals(r2))
	assert_false(r1.contains_point(SimPoint.new(-1, -1)))
	assert_true(r2.contains_point(SimPoint.new(0, 0)))
	assert_true(r2.contains_point(SimPoint.new(1, 1)))
	assert_true(r1.intersects(r2))
	assert_false(r1.intersects(r3))


func test_circle() -> void:
	var c1 := SimCircle.new(SimPoint.new(0, 0), 1)
	var c2 := SimCircle.new(SimPoint.new(0, 0), 2)
	var c3 := SimCircle.new(SimPoint.new(0, 0), 0)
	assert_false(c1.equals(c2))
	assert_eq(
		[[-1, 0], [0, -1], [0, 0], [0, 1], [1, 0]],
		c1.get_coordinates()
	)
	assert_eq([[0, 0]], c3.get_coordinates())
