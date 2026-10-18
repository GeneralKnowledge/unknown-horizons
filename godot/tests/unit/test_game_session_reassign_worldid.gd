extends GutTest


func test_reassign_worldid_updates_registry() -> void:
	var session := GameSession.new()
	var old_settlement_id := session.settlement.worldid
	assert_true(session.registry.has_id(old_settlement_id))
	assert_false(session.registry.has_id(9001))
	assert_true(session.reassign_worldid(session.settlement, 9001))
	assert_eq(9001, session.settlement.worldid)
	assert_false(session.registry.has_id(old_settlement_id))
	assert_same(session.settlement, session.registry.get_by_id(9001))
	assert_true(session.reassign_worldid(session.settlement, 9001))
	assert_false(session.reassign_worldid(session.settlement, session.island.worldid))
