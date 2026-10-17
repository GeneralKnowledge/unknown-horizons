extends GutTest


func test_trivial() -> void:
	var b := _building_with_health(20)
	assert_eq(20, b.health.health)
	assert_eq(20, b.health.maxhealth)


func test_maxhealth_required() -> void:
	var b := _building_with_health(1000)
	assert_eq(1000, b.health.maxhealth)


func test_damage() -> void:
	var b := _building_with_health(20)
	b.health.deal_damage(1, 19)
	assert_eq(1, b.health.health)
	assert_false(b.health.is_destroyed())


func test_damage_zero_health() -> void:
	var session := GameSession.new()
	session.load_test_map()
	GameTestHelpers.settle(session)
	var b: Building = session.manager.execute(
		BuildCommand.new(
			GameConstants.BUILDINGS["LOOKOUT"],
			32,
			32,
			session.island,
			session.settlement
		)
	) as Building
	b.health.deal_damage(1, 1000)
	assert_eq(0, b.health.health)
	assert_true(b.health.is_destroyed())


func test_huge_damage() -> void:
	var b := _building_with_health(20)
	b.health.deal_damage(1, 300)
	assert_eq(0, b.health.health)
	assert_true(b.health.is_destroyed())


func _building_with_health(maxhealth: int) -> Building:
	var session := GameSession.new()
	session.load_test_map()
	var inv := PositiveSizedSpecializedInventory.new({})
	var b := Building.new(1, GameConstants.BUILDINGS["LOOKOUT"], Vector2i(0, 0), session.island, null, inv, null)
	b.health = HealthComponent.new(b, {"maxhealth": maxhealth})
	return b
