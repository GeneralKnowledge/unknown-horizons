class_name TileOrientation
extends RefCounted

## Port of horizons/util/tile_orientation.py (road/wall alignment keys).

const ACTION_OFFSETS: Array = [
	["a", 0, -1],
	["b", 1, 0],
	["c", 0, 1],
	["d", -1, 0],
	["e", 1, -1],
	["f", 1, 1],
	["g", -1, 1],
	["h", -1, -1],
]


static func get_tile_alignment_action(origin: SimPoint, is_similar_tile: Callable) -> String:
	var action := ""
	for entry in ACTION_OFFSETS:
		var part: String = entry[0]
		var xoff: int = entry[1]
		var yoff: int = entry[2]
		if not is_similar_tile.call(origin.offset(xoff, yoff)):
			continue
		if part in "abcd":
			action += part
		if part in "efgh":
			var left_code := part.unicode_at(0) - 4
			var right_code := part.unicode_at(0) - 3 - (4 if part == "h" else 0)
			var fill_left := String.chr(left_code) in action
			var fill_right := String.chr(right_code) in action
			if fill_left and fill_right:
				action += part
	if action == "":
		return "single"
	return action
