extends GutTest


func test_animation_idle_on_fresh_building() -> void:
	var gts := GameTestSession.start(true)
	var jack: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	assert_not_null(jack)
	var anim: StringName = BuildingVisualRegistry.animation_for_building(jack)
	assert_eq(&"idle", anim)


func test_animation_working_when_producing() -> void:
	var gts := GameTestSession.start(true)
	var jack: Building = gts.build(GameConstants.BUILDINGS["LUMBERJACK"], 30, 30)
	gts.build_ownerless(GameConstants.BUILDINGS["TREE"], 32, 30)
	gts.run_seconds(5)
	var producer := jack.get_producer()
	assert_not_null(producer)
	if producer._get_current_state() == ProductionStates.PRODUCING:
		assert_eq(&"working", BuildingVisualRegistry.animation_for_building(jack))
