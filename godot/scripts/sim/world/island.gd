class_name Island
extends RefCounted

var worldid: int
var session: GameSession
var settlements: Array[Settlement] = []


func _init(p_worldid: int, p_session: GameSession) -> void:
	worldid = p_worldid
	session = p_session
