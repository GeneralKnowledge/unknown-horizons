class_name GameTestHelpers
extends RefCounted

const FARM_FIELD_OFFSETS: Array[Vector2i] = [
	Vector2i(-3, -3),
	Vector2i(-3, 0),
	Vector2i(-3, 3),
	Vector2i(0, 3),
	Vector2i(3, 3),
	Vector2i(3, 0),
	Vector2i(3, -3),
	Vector2i(0, -3),
]


static func new_settlement(session: GameSession, pos: Vector2i = TestMapFactory.default_settlement_point()) -> Dictionary:
	var warehouse: Building = session.manager.execute(
		BuildCommand.new(
			GameConstants.BUILDINGS["WAREHOUSE"],
			pos.x,
			pos.y,
			session.island,
			session.settlement
		)
	) as Building
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


static func build_farm(gts: GameTestSession, x: int, y: int, field_ids: Array = []) -> Building:
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], x, y)
	if farm == null:
		return null
	var limit := mini(field_ids.size(), FARM_FIELD_OFFSETS.size())
	for i in range(limit):
		var off: Vector2i = FARM_FIELD_OFFSETS[i]
		gts.build(int(field_ids[i]), x + off.x, y + off.y)
	return farm
