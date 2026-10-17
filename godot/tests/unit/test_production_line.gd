extends GutTest


func test_init() -> void:
	var data := {
		"enabled_by_default": false,
		"time": 90,
		"level": [0, 1, 2],
		"changes_animation": false,
		"produces": [[14, 1]],
		"consumes": [[19, -1]],
	}
	var line := ProductionLine.new(1, data)
	assert_eq(90, line.time)
	assert_eq(false, line.changes_animation)
	assert_eq(1, line.production[14])
	assert_eq(-1, line.production[19])
