class_name Building
extends RefCounted

var worldid: int
var building_id: int
var position: Vector2i
var island: Island
var settlement: Settlement
var inventory: Inventory
var producer: Producer
var collecting: CollectingComponent


func _init(
	p_worldid: int,
	p_building_id: int,
	p_position: Vector2i,
	p_island: Island,
	p_settlement: Settlement,
	p_inventory: Inventory,
	p_producer: Producer
) -> void:
	worldid = p_worldid
	building_id = p_building_id
	position = p_position
	island = p_island
	settlement = p_settlement
	inventory = p_inventory
	producer = p_producer


func get_storage() -> Inventory:
	return inventory


func get_producer() -> Producer:
	return producer
