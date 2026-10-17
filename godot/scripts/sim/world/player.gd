class_name SimPlayer
extends RefCounted

var worldid: int
var settlement: Settlement


func _init(p_worldid: int, p_settlement: Settlement) -> void:
	worldid = p_worldid
	settlement = p_settlement
