class_name CollectorJob
extends RefCounted

class JobObject:
	var id: int
	var loading_area: SimPoint

	func _init(building: Building) -> void:
		id = building.worldid
		loading_area = SimPoint.new(building.position.x, building.position.y)


var object: JobObject
var target: Building
var resources: Array
var available: int
var target_inventory_full_num: int = 0


func _init(p_target: Building, p_resources: Array, p_available: int) -> void:
	target = p_target
	object = JobObject.new(p_target)
	resources = p_resources
	available = p_available
