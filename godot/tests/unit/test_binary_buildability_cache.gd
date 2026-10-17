extends GutTest

var _terrain: TerrainBuildabilityCache
var _bc: BinaryBuildabilityCache


func before_each() -> void:
	var land := CoordSet.new()
	for x in range(10):
		for y in range(10):
			land.add(Vector2i(x, y))
	_terrain = TerrainBuildabilityCache.new(land)
	_bc = BinaryBuildabilityCache.new(_terrain)


func test_add_area_tracks_coords() -> void:
	assert_eq(0, _bc.coords_set.size())
	_bc.add_area([Vector2i(1, 1), Vector2i(2, 1)])
	assert_eq(2, _bc.coords_set.size())
	assert_true(_bc.coords_set.has(Vector2i(1, 1)))
