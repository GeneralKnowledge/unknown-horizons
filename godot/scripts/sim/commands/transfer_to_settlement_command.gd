class_name TransferToSettlementCommand
extends SimCommand

var building: Building
var res_id: int
var amount: int


func _init(p_building: Building, p_res_id: int, p_amount: int) -> void:
	building = p_building
	res_id = p_res_id
	amount = p_amount


func execute(session: GameSession) -> Variant:
	if building == null or building.settlement == null:
		return 0
	var from_inv := building.get_storage()
	var to_inv := building.settlement.inventory
	var available := mini(amount, from_inv.amount(res_id))
	var moved := 0
	while moved < available:
		if to_inv.get_free_space_for(res_id) <= 0:
			break
		from_inv.alter(res_id, -1)
		to_inv.alter(res_id, 1)
		moved += 1
	if moved > 0:
		MessageBus.inventory_changed.emit(to_inv)
		MessageBus.settlement_updated.emit()
	return moved
