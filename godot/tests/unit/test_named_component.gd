extends GutTest


func before_each() -> void:
	NamedComponent.reset()


func test_new_default_name() -> void:
	var c := _make_named("")
	assert_eq("Building", c.name)
	var c2 := _make_named("")
	assert_eq("Building 2", c2.name)


func test_duplicates() -> void:
	var c := _make_named("")
	var c2 := _make_named("")
	c2.set_name("Building")
	assert_eq("Building", c2.name)
	c.set_name("Test name")
	assert_eq("Test name", c.name)


func test_rename_none() -> void:
	var c := _make_named("")
	c.set_name("Test name")
	c.set_name("")
	assert_true(c.name.begins_with("Building"))


func test_new_named_object() -> void:
	var c := _make_named("Test name")
	assert_eq("Test name", c.name)


func test_unchanged_rename() -> void:
	var c := _make_named("")
	c.set_name("Building")
	var c2 := _make_named("")
	assert_eq("Building 2", c2.name)


func test_reset() -> void:
	_make_named("")
	NamedComponent.reset()
	assert_eq("Building", _make_named("").name)


func _make_named(initial: String) -> NamedComponent:
	var session := GameSession.new()
	var b := Building.new(1, 1, Vector2i(0, 0), session.island, null, null, null)
	var cfg := {} if initial.is_empty() else {"name": initial}
	return NamedComponent.new(b, cfg)
