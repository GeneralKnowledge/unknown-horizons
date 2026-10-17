extends GutTest


func test_grid_aabb_from_test_map() -> void:
	var session := GameSession.new()
	session.load_test_map()
	var rect := MapGroundBounds.compute_grid_aabb(session.island)
	assert_gt(rect.size.x, 0)
	assert_gt(rect.size.y, 0)


func test_screen_aabb_spans_isometric_projection() -> void:
	var map_view := MapView.new()
	var session := GameSession.new()
	session.load_test_map()
	map_view.bind(session.island)
	var grid := MapGroundBounds.compute_grid_aabb(session.island)
	var p1 := map_view.grid_to_screen(grid.position)
	var p2 := map_view.grid_to_screen(grid.position + grid.size - Vector2i.ONE)
	assert_ne(p1, p2)
