class_name TradePostComponent
extends RefCounted

## Simplified trade post (buy/sell slots) for sim tests.

class Slot:
	var resource_id: int = -1
	var is_sell: bool = false
	var limit: int = 0


var home_building: Building
var slots: Array[Slot] = []
var buy_expenses: int = 0
var sell_income: int = 0
var total_expenses: int = 0
var total_earnings: int = 0
var owner_inventory: Inventory


func _init(p_building: Building, owner_inv: Inventory) -> void:
	home_building = p_building
	owner_inventory = owner_inv
	for _i in range(8):
		slots.append(Slot.new())


func set_slot(index: int, resource_id: int, is_sell: bool, limit: int) -> void:
	if index < 0 or index >= slots.size():
		return
	var slot: Slot = slots[index]
	slot.resource_id = resource_id
	slot.is_sell = is_sell
	slot.limit = limit


func clear_slot(index: int, _clear_stats: bool = true) -> void:
	set_slot(index, -1, false, 0)


func buy(resource_id: int, amount: int, price: int, _player_id: int) -> bool:
	for slot in slots:
		if slot.resource_id != resource_id or slot.is_sell:
			continue
		if owner_inventory.amount(GameConstants.RES["GOLD"]) < price:
			return false
		if home_building.get_storage().get_free_space_for(resource_id) < amount:
			return false
		if amount + home_building.get_storage().amount(resource_id) > slot.limit:
			return false
		owner_inventory.alter(GameConstants.RES["GOLD"], -price)
		home_building.get_storage().alter(resource_id, amount)
		buy_expenses += price
		total_expenses += amount * price
		return true
	return false


func sell(resource_id: int, amount: int, price: int, _player_id: int) -> bool:
	for slot in slots:
		if slot.resource_id != resource_id or not slot.is_sell:
			continue
		if home_building.get_storage().amount(resource_id) < amount:
			return false
		home_building.get_storage().alter(resource_id, -amount)
		owner_inventory.alter(GameConstants.RES["GOLD"], price)
		sell_income += price
		total_earnings += amount * price
		return true
	return false
