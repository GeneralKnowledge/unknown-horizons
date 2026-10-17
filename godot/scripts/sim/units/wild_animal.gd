class_name WildAnimal
extends RefCounted

var worldid: int
var island: Island
var position: Vector2i
var session: GameSession
var unit_id: int = GameConstants.UNITS["WILD_ANIMAL"]
var inventory: Inventory
var producer: Producer


func _init(
	p_worldid: int,
	p_island: Island,
	p_position: Vector2i,
	p_session: GameSession,
	p_inventory: Inventory,
	p_lines: Dictionary
) -> void:
	worldid = p_worldid
	island = p_island
	position = p_position
	session = p_session
	inventory = p_inventory
	if not p_lines.is_empty():
		producer = Producer.new(self, p_session.scheduler, p_lines)


func get_storage() -> Inventory:
	return inventory


func get_producer() -> Producer:
	return producer
