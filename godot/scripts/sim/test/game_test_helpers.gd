class_name GameTestHelpers
extends RefCounted


static func new_settlement(session: GameSession, pos: Vector2i = TestMapFactory.default_settlement_point()) -> Dictionary:
	var warehouse := BuildCommand.new(
		GameConstants.BUILDINGS["WAREHOUSE"],
		pos.x,
		pos.y,
		session.island,
		session.settlement
	).execute(session)
	if warehouse == null:
		push_error("Could not build warehouse at %s" % pos)
		return {"settlement": session.settlement, "island": session.island}
	return {"settlement": warehouse.settlement, "island": session.island}


static func settle(session: GameSession) -> Dictionary:
	var settled := new_settlement(session)
	var settlement: Settlement = settled.settlement
	settlement.inventory.alter(GameConstants.RES["GOLD"], 5000)
	settlement.inventory.alter(GameConstants.RES["BOARDS"], 50)
	settlement.inventory.alter(GameConstants.RES["TOOLS"], 50)
	settlement.inventory.alter(GameConstants.RES["BRICKS"], 50)
	return settled
