extends GutTest


func test_create_map_land_border() -> void:
	var ground := TestMapFactory.create_ground_map()
	assert_eq(SimGround.Kind.LAND, ground[TestMapFactory.ISLAND_ORIGIN + Vector2i(1, 1)])
	assert_eq(SimGround.Kind.SHALLOW_WATER, ground[TestMapFactory.ISLAND_ORIGIN])
