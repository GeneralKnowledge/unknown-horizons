class_name NamedComponent
extends RefCounted

static var _names_used: Array[String] = []

var home_building: Building
var _base_name: String = "Building"
var name: String = "Building"


static func reset() -> void:
	_names_used.clear()


static func _allocate_name(base: String) -> String:
	var candidate := base
	var suffix := 2
	while candidate in _names_used:
		candidate = "%s %d" % [base, suffix]
		suffix += 1
	_names_used.append(candidate)
	return candidate


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	if config.has("name"):
		_base_name = str(config["name"])
	else:
		_base_name = "Building"
	name = _allocate_name(_base_name)


func set_name(new_name: String) -> void:
	if new_name == null or str(new_name).is_empty():
		name = _allocate_name(_base_name)
		return
	if name in _names_used:
		_names_used.erase(name)
	name = str(new_name)
	if name not in _names_used:
		_names_used.append(name)
