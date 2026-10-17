class_name SimRect
extends RefCounted

var top: int
var left: int
var right: int
var bottom: int


func _init(a = null, b = null, c = null, d = null) -> void:
	if a is SimPoint and b is SimPoint:
		top = mini(a.y, b.y)
		left = mini(a.x, b.x)
		right = maxi(a.x, b.x)
		bottom = maxi(a.y, b.y)
	elif a is SimPoint and typeof(b) == TYPE_INT and typeof(c) == TYPE_INT:
		top = a.y
		left = a.x
		right = left + int(b)
		bottom = top + int(c)
	elif typeof(a) == TYPE_INT and typeof(b) == TYPE_INT and typeof(c) == TYPE_INT and typeof(d) == TYPE_INT:
		left = mini(int(a), int(c))
		right = maxi(int(a), int(c))
		top = mini(int(b), int(d))
		bottom = maxi(int(b), int(d))
	else:
		assert(false, "Invalid SimRect constructor")


static func from_edges(l: int, t: int, r: int, b: int) -> SimRect:
	var rect := SimRect.new()
	rect.left = l
	rect.top = t
	rect.right = r
	rect.bottom = b
	return rect


func contains_point(point: SimPoint) -> bool:
	return left <= point.x and point.x <= right and top <= point.y and point.y <= bottom


func intersects(other: SimRect) -> bool:
	return not (other.right < left or right < other.left or other.bottom < top or bottom < other.top)


func equals(other: SimRect) -> bool:
	return (
		top == other.top
		and left == other.left
		and right == other.right
		and bottom == other.bottom
	)
