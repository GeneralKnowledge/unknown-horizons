class_name SimPoint
extends RefCounted

var x: int
var y: int


func _init(p_x: int, p_y: int) -> void:
	x = p_x
	y = p_y


func copy() -> SimPoint:
	return SimPoint.new(x, y)


func offset(x_off: int, y_off: int) -> SimPoint:
	return SimPoint.new(x + x_off, y + y_off)


func distance_to(other) -> float:
	var ox: int
	var oy: int
	if other is SimPoint:
		ox = other.x
		oy = other.y
	elif other is Vector2i:
		ox = other.x
		oy = other.y
	else:
		ox = int(other[0])
		oy = int(other[1])
	return sqrt(float((x - ox) ** 2 + (y - oy) ** 2))


func get_coordinates() -> Array:
	return [[x, y]]


func equals(other) -> bool:
	if other == null:
		return false
	if other is SimPoint:
		return x == other.x and y == other.y
	return x == other[0] and y == other[1]
