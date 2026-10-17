extends GutTest


func _make_accessor(grid: Array) -> Callable:
	return func(point: SimPoint) -> bool:
		return grid[point.y + 1][point.x + 1] == "x"


func _grid_from_text(text: String) -> Array:
	var lines := text.strip_edges().split("\n")
	var grid: Array = []
	for line in lines:
		grid.append(line.strip_edges().split(" "))
	return grid


func _assert_alignment(expected: String, tiles: String) -> void:
	var grid := _grid_from_text(tiles)
	var aligned := TileOrientation.get_tile_alignment_action(
		SimPoint.new(0, 0),
		_make_accessor(grid)
	)
	assert_eq(expected, aligned)


func test_single() -> void:
	_assert_alignment("single", """
		_ _ _
		_ . _
		_ _ _
	""")


func test_d() -> void:
	_assert_alignment("d", """
		_ _ _
		x . _
		_ _ _
	""")


func test_bd() -> void:
	_assert_alignment("bd", """
		_ _ _
		x . x
		_ _ _
	""")


func test_abdh() -> void:
	_assert_alignment("abdh", """
		x x _
		x . x
		_ _ _
	""")


func test_abcdefgh() -> void:
	_assert_alignment("abcdefgh", """
		x x x
		x . x
		x x x
	""")
