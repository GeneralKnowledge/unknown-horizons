class_name BuildCommand
extends RefCounted

var building_id: int
var x: int
var y: int
var island: Island
var settlement: Settlement


func _init(
	p_building_id: int,
	p_x: int,
	p_y: int,
	p_island: Island,
	p_settlement: Settlement = null
) -> void:
	building_id = p_building_id
	x = p_x
	y = p_y
	island = p_island
	settlement = p_settlement


func execute(session: GameSession) -> Building:
	if settlement == null:
		settlement = island.settlements[0]
	var export := ContentLoader.load_building_export(_stem_for_building(building_id))
	var inventory := ContentLoader.create_storage_from_export(export)
	var lines := ContentLoader.create_producer_lines(export)
	var worldid := session.allocate_worldid()
	var building := Building.new(
		worldid,
		building_id,
		Vector2i(x, y),
		island,
		settlement,
		inventory,
		null
	)
	var producer := Producer.new(building, session.scheduler, lines)
	building.producer = producer
	settlement.buildings.append(building)
	session.register_building(building)
	return building


func _stem_for_building(building_id: int) -> String:
	if building_id == GameConstants.BUILDINGS["LUMBERJACK"]:
		return "lumberjackcamp"
	push_error("Unknown building id %s" % building_id)
	return "lumberjackcamp"
