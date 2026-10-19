class_name GameTestHelpers
extends RefCounted

const FoundSettlementCommand = preload("res://scripts/sim/commands/found_settlement_command.gd")
const _FarmFieldPlacement = preload("res://scripts/sim/world/farm_field_placement.gd")


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


static func found_settlement_from_ship(
	session: GameSession,
	ship: LegacyUnit,
	warehouse_x: int,
	warehouse_y: int
) -> Building:
	return session.manager.execute(
		FoundSettlementCommand.new(ship, warehouse_x, warehouse_y)
	) as Building


static func settle(session: GameSession) -> Dictionary:
	var settled := new_settlement(session)
	var settlement: Settlement = settled.settlement
	settlement.inventory.alter(GameConstants.RES["GOLD"], 5000)
	settlement.inventory.alter(GameConstants.RES["BOARDS"], 50)
	settlement.inventory.alter(GameConstants.RES["TOOLS"], 50)
	settlement.inventory.alter(GameConstants.RES["BRICKS"], 50)
	return settled


static func build_farm(gts: GameTestSession, x: int, y: int, field_ids: Array = []) -> Building:
	var farm: Building = gts.build(GameConstants.BUILDINGS["FARM"], x, y, false)
	if farm == null:
		return null
	if field_ids.is_empty():
		_FarmFieldPlacement.place_surrounding_fields(gts.session, farm)
		return farm
	var offsets: Array = _FarmFieldPlacement.FIELD_OFFSETS
	var limit := mini(field_ids.size(), offsets.size())
	for i in range(limit):
		var off: Vector2i = offsets[i]
		gts.build(int(field_ids[i]), x + off.x, y + off.y)
	return farm
