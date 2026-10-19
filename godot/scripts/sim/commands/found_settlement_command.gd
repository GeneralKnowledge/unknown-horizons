class_name FoundSettlementCommand
extends SimCommand

const _Rules = preload("res://scripts/sim/world/found_settlement_rules.gd")

var ship: LegacyUnit
var warehouse_x: int
var warehouse_y: int


func _init(p_ship: LegacyUnit, p_x: int, p_y: int) -> void:
	ship = p_ship
	warehouse_x = p_x
	warehouse_y = p_y


func execute(session: GameSession) -> Variant:
	if ship == null or session == null or session.island == null:
		return null
	var settlement: Settlement = session.settlement
	if not _Rules.is_unfounded(settlement):
		return null
	var origin := Vector2i(warehouse_x, warehouse_y)
	if ship.island != session.island:
		return null
	if not _Rules.ship_near_warehouse_site(ship, origin):
		return null
	var warehouse_id := GameConstants.BUILDINGS["WAREHOUSE"]
	if not _Rules.can_place_founding_warehouse(
		session.island, settlement, warehouse_id, origin
	):
		return null
	if not _pay_warehouse_costs(ship, settlement, warehouse_id):
		return null
	var cmd := BuildCommand.new(warehouse_id, warehouse_x, warehouse_y, session.island, settlement)
	cmd.skip_cost = true
	var warehouse: Building = session.manager.execute(cmd) as Building
	if warehouse == null:
		return null
	_transfer_ship_cargo_to_settlement(ship, settlement)
	MessageBus.settlement_founded.emit(settlement, warehouse)
	return warehouse


static func _pay_warehouse_costs(ship: LegacyUnit, settlement: Settlement, building_id: int) -> bool:
	var costs := BuildingCosts.costs_for_building_id(building_id)
	if costs.is_empty():
		return true
	for res_id in costs.keys():
		var need: int = int(costs[res_id])
		var from_ship := 0
		if ship.inventory != null:
			from_ship = mini(need, ship.inventory.amount(int(res_id)))
			if from_ship > 0:
				ship.inventory.alter(int(res_id), -from_ship)
		var remaining := need - from_ship
		if remaining > 0:
			if settlement.inventory.amount(int(res_id)) < remaining:
				return false
			settlement.inventory.alter(int(res_id), -remaining)
	return true


static func _transfer_ship_cargo_to_settlement(ship: LegacyUnit, settlement: Settlement) -> void:
	if ship.inventory == null:
		return
	for res_id in ship.inventory.get_stored_resources().keys():
		var rid := int(res_id)
		var amount := ship.inventory.amount(rid)
		if amount <= 0:
			continue
		var free := settlement.inventory.get_free_space_for(rid)
		if free <= 0:
			continue
		var moved := mini(amount, free)
		ship.inventory.alter(rid, -moved)
		settlement.inventory.alter(rid, moved)
