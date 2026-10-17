extends GutTest


func test_init() -> void:
	var data := {
		"enabled_by_default": false,
		"time": 90,
		"changes_animation": false,
		"produces": [[14, 1]],
		"consumes": [[19, -1]],
	}
	var line := ProductionLine.new(1, data)
	assert_eq(90, line.time)
	assert_eq(false, line.changes_animation)
	assert_eq(1, line.production[14])
	assert_eq(-1, line.production[19])


func test_alter_production_time() -> void:
	var line := ProductionLine.new(1, {"time": 10})
	assert_eq(10, line.time)
	line.alter_production_time(2)
	assert_eq(20, line.time)
	line.alter_production_time(2)
	assert_eq(20, line.time)
	line.alter_production_time(1.5)
	assert_eq(15.0, line.time)


func test_change_amount() -> void:
	var line := ProductionLine.new(1, {
		"time": 10,
		"produces": [[2, 3]],
		"consumes": [[4, -5]],
	})
	line.change_amount(2, 10)
	assert_eq(line.production[2], 10)
	assert_eq(line.production[4], -5)
	assert_eq(line.produced_res[2], 10)
	assert_eq(line.consumed_res[4], -5)
	line.change_amount(4, -1)
	assert_eq(line.production[2], 10)
	assert_eq(line.production[4], -1)
