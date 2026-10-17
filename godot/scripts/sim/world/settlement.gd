class_name Settlement
extends RefCounted

var worldid: int
var island: Island
var inventory: Inventory
var buildings: Array[Building] = []


func _init(p_worldid: int, p_island: Island, p_inventory: Inventory) -> void:
	worldid = p_worldid
	island = p_island
	inventory = p_inventory
