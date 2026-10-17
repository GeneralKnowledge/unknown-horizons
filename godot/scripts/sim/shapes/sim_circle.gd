class_name SimCircle
extends RefCounted

var center: SimPoint
var radius: int


func _init(p_center: SimPoint, p_radius: int) -> void:
	center = p_center
	radius = p_radius


func get_coordinates() -> Array:
	var out: Array = []
	var cx := center.x
	var cy := center.y
	var radius_sq := radius * radius
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			var dx := cx - x
			var dy := cy - y
			if dx * dx + dy * dy <= radius_sq:
				out.append([x, y])
	return out


func equals(other: SimCircle) -> bool:
	return center.equals(other.center) and radius == other.radius
