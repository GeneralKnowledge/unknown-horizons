extends GutTest

## Legacy tests/game/test_bugs.py test_ticket_1523 (FieldUtilization on farms).


func test_farm_capacity_utilization_with_potato_fields() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = GameTestHelpers.build_farm(
		gts,
		30,
		30,
		[
			GameConstants.BUILDINGS["POTATO_FIELD"],
			GameConstants.BUILDINGS["POTATO_FIELD"],
			GameConstants.BUILDINGS["POTATO_FIELD"],
			GameConstants.BUILDINGS["POTATO_FIELD"],
		]
	)
	if farm == null:
		pending("FARM build failed on test map")
		return
	assert_not_null(farm.producer)
	assert_eq("FieldUtilization", farm.producer.get_utilization_kind())
	var provider_count := farm.get_providers().size()
	assert_gte(provider_count, 3)
	var expected := float(provider_count) / 8.0
	assert_almost_eq(expected, farm.producer.capacity_utilization(), 0.001)
	assert_false(farm.producer.capacity_utilization_below(expected - 0.05))


func test_farm_provider_resource_compatibility() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30)
	if farm == null:
		pending("FARM build failed on test map")
		return
	var off: Vector2i = GameTestHelpers.FARM_FIELD_OFFSETS[1]
	var corn_field: Building = gts.build(
		GameConstants.BUILDINGS["CORN_FIELD"],
		farm.position.x + off.x,
		farm.position.y + off.y
	)
	if corn_field == null:
		pending("CORN_FIELD build failed on test map")
		return
	var consumed: Array = farm._consumed_resource_ids()
	assert_has(consumed, GameConstants.RES["GRAIN"])
	assert_true(
		Building.field_provides_any_resource(corn_field, consumed),
		"corn field produces GRAIN which the farm consumes"
	)
	assert_false(
		Building.field_provides_any_resource(
			corn_field,
			[GameConstants.RES["POTATOES"]]
		),
		"corn field must not count as potato crop provider"
	)
	assert_false(
		Building.field_provides_any_resource(
			corn_field,
			[GameConstants.RES["CORN"]]
		),
		"CORN is farm output, not an input matched to field produce"
	)
	var providers := farm.get_providers()
	assert_eq(1, providers.size())
	assert_eq(corn_field.worldid, (providers[0] as Building).worldid)


func test_lumberjack_field_builder_fill_range() -> void:
	var gts := GameTestSession.start(true)
	var lj: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	if lj == null:
		pending("LUMBERJACK build failed on test map")
		return
	assert_not_null(lj.field_builder)
	var before := 0
	for b in gts.session.get_buildings_on_island(gts.session.island):
		if b.building_id == GameConstants.BUILDINGS["TREE"]:
			before += 1
	var placed := lj.field_builder.fill_range(gts.session)
	assert_gte(placed, 1)
	var after := 0
	for b in gts.session.get_buildings_on_island(gts.session.island):
		if b.building_id == GameConstants.BUILDINGS["TREE"]:
			after += 1
	assert_gt(after, before)
