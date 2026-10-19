extends GutTest

## Legacy provider_buildings / get_providers_in_range for collectors and farms.


func test_tree_registered_as_trees_provider() -> void:
	var gts := GameTestSession.start(true)
	var tree: Building = gts.build(GameConstants.BUILDINGS["TREE"], 30, 35)
	if tree == null:
		pending("TREE build failed on test map")
		return
	if gts.session.settlement.buildings.is_empty():
		pending("settlement has no warehouse")
		return
	var wh: Building = gts.session.settlement.buildings[0] as Building
	var listed: Array = gts.session.island.get_providers_in_range(
		wh,
		99,
		[GameConstants.RES["TREES"]],
		gts.session.settlement
	)
	assert_true(tree in listed)


func test_lumberjack_collector_ignores_non_tree_providers() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	var corn: Building = gts.build(GameConstants.BUILDINGS["CORN_FIELD"], 27, 33)
	if lj == null or corn == null:
		pending("build failed on test map")
		return
	corn.get_storage().alter(GameConstants.RES["GRAIN"], 5)
	var providers: Array = gts.session.island.get_providers_in_range(
		lj,
		3,
		[GameConstants.RES["TREES"]],
		gts.session.settlement
	)
	assert_false(corn in providers)


func test_farm_get_providers_uses_same_index() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30)
	var off: Vector2i = GameTestHelpers.FARM_FIELD_OFFSETS[1]
	var corn: Building = gts.build(
		GameConstants.BUILDINGS["CORN_FIELD"],
		farm.position.x + off.x,
		farm.position.y + off.y
	)
	if farm == null:
		pending("FARM build failed on test map")
		return
	if corn == null:
		pending("CORN_FIELD build failed on test map")
		return
	var from_farm: Array = farm.get_providers()
	var from_index: Array = gts.session.island.get_providers_in_range(
		farm,
		farm.get_radius(),
		farm._consumed_resource_ids(),
		farm.settlement
	)
	assert_true(corn in from_farm)
	assert_eq(from_farm.size(), from_index.size())
