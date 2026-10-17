class_name ConnectedAreaCache
extends RefCounted

## Port of horizons/world/buildability/connectedareacache.py

const _MOVES: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(1, 0),
]

var area_numbers: Dictionary = {} # Vector2i -> int
var areas: Dictionary = {} # int -> Dictionary (Vector2i -> true)
var _next_area_id: int = 1


func _label_area(seed_coords: Vector2i) -> void:
	var area_id := _next_area_id
	_next_area_id += 1
	area_numbers[seed_coords] = area_id
	var new_area: Dictionary = {seed_coords: true}
	areas[area_id] = new_area
	var queue: Array[Vector2i] = [seed_coords]
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		for move in _MOVES:
			var coords := pos + move
			if not area_numbers.has(coords):
				continue
			if int(area_numbers[coords]) == area_id:
				continue
			area_numbers[coords] = area_id
			new_area[coords] = true
			queue.append(coords)


func _renumber_affected_areas(affected_areas: Dictionary) -> void:
	for area_id in affected_areas.keys():
		var area_dict: Dictionary = areas[area_id]
		for coords in area_dict.keys():
			if int(area_numbers[coords]) == area_id:
				_label_area(coords)
				assert(int(area_numbers[coords]) != area_id)
		areas.erase(area_id)


func add_area(coords_list: Array) -> void:
	var affected_areas: Dictionary = {}
	for coords in coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		assert(not area_numbers.has(c))
		var nearby_areas: Array[int] = []
		for move in _MOVES:
			var neighbor: Vector2i = c + move
			if area_numbers.has(neighbor):
				var area_id := int(area_numbers[neighbor])
				if not nearby_areas.has(area_id):
					nearby_areas.append(area_id)
		if nearby_areas.is_empty():
			var new_id := _next_area_id
			_next_area_id += 1
			area_numbers[c] = new_id
			areas[new_id] = {c: true}
		else:
			var use_id: int = nearby_areas[0]
			area_numbers[c] = use_id
			areas[use_id][c] = true
			if nearby_areas.size() > 1:
				for nearby_area_id in nearby_areas:
					affected_areas[nearby_area_id] = true
	_renumber_affected_areas(affected_areas)


func remove_area(coords_list: Array) -> void:
	var affected_areas: Dictionary = {}
	for coords in coords_list:
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		var area_id := int(area_numbers[c])
		area_numbers.erase(c)
		affected_areas[area_id] = true
		areas[area_id].erase(c)
	_renumber_affected_areas(affected_areas)


func area_coords_for(point: Vector2i) -> Dictionary:
	var id := int(area_numbers[point])
	return areas[id]
