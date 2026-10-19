extends GutTest

const _FarmFieldPlacement = preload("res://scripts/sim/world/farm_field_placement.gd")
const FillFarmFieldsCommand = preload("res://scripts/sim/commands/fill_farm_fields_command.gd")


func _count_fields_on_island(gts: GameTestSession, field_building_id: int) -> int:
	var n := 0
	for b in gts.session.get_buildings_on_island(gts.session.island):
		if b.building_id == field_building_id:
			n += 1
	return n


func test_build_command_auto_places_surrounding_fields() -> void:
	var gts := GameTestSession.start(true)
	var before := _count_fields_on_island(gts, GameConstants.BUILDINGS["POTATO_FIELD"])
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30)
	if farm == null:
		pending("FARM build failed on test map")
		return
	var expected_field_id := _FarmFieldPlacement.default_field_id_for_farm(farm)
	assert_gt(expected_field_id, 0, "farm should map to a crop field building")
	var after := _count_fields_on_island(gts, expected_field_id)
	assert_gt(after, before, "auto farm build should place at least one surrounding field")


func test_fill_farm_fields_command() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30, false)
	if farm == null:
		pending("FARM build failed on test map")
		return
	var field_id := GameConstants.BUILDINGS["POTATO_FIELD"]
	var placed: int = gts.session.manager.execute(
		FillFarmFieldsCommand.new(farm, field_id, 3)
	)
	assert_gte(placed, 1)
	assert_lte(placed, 3)
	assert_gte(_count_fields_on_island(gts, field_id), placed)


func test_placement_stops_when_unaffordable() -> void:
	var gts := GameTestSession.start(true)
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], 30, 30, false)
	if farm == null:
		pending("FARM build failed on test map")
		return
	var settlement := farm.settlement
	for res_name in GameConstants.RES:
		var res_id: int = int(GameConstants.RES[res_name])
		settlement.inventory.alter(res_id, -settlement.inventory.amount(res_id))
	var field_id := GameConstants.BUILDINGS["POTATO_FIELD"]
	assert_false(
		BuildingCosts.can_afford(settlement, field_id),
		"settlement must not afford a field for this test"
	)
	var placed := _FarmFieldPlacement.place_surrounding_fields(gts.session, farm, field_id, 8)
	assert_eq(placed, 0, "cannot afford fields — ring fill should stop immediately")
