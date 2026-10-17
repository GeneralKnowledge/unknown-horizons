class_name ProductionLine
extends RefCounted

var id: int
var time: float = 1.0
var changes_animation: bool = true
var save_statistics: bool = true
var production: Dictionary = {}
var produced_res: Dictionary = {}
var consumed_res: Dictionary = {}
var unit_production: Dictionary = {}
var _raw_data: Dictionary = {}


func _init(p_id: int, data: Dictionary) -> void:
	id = p_id
	_raw_data = data if data else {}
	_parse()


func _parse() -> void:
	time = float(_raw_data.get("time", 1))
	changes_animation = bool(_raw_data.get("changes_animation", true))
	save_statistics = bool(_raw_data.get("save_statistics", true))
	production.clear()
	produced_res.clear()
	consumed_res.clear()
	unit_production.clear()
	const UNITS_DIFF := 1000000 # UNITS.DIFFERENCE_BUILDING_UNIT_ID approx
	if _raw_data.has("produces"):
		for entry in _raw_data["produces"]:
			var produced_object: int = int(entry[0])
			var amount: int = int(entry[1])
			if produced_object < UNITS_DIFF:
				production[produced_object] = amount
				produced_res[produced_object] = amount
			else:
				unit_production[produced_object] = amount
	if _raw_data.has("consumes"):
		for entry in _raw_data["consumes"]:
			var res: int = int(entry[0])
			var amount: int = int(entry[1])
			production[res] = amount
			consumed_res[res] = amount


func alter_production_time(modifier: float) -> void:
	time = float(_raw_data.get("time", 1)) * modifier


func change_amount(res: int, amount: int) -> void:
	production[res] = amount
	if consumed_res.has(res):
		consumed_res[res] = amount
	if produced_res.has(res):
		produced_res[res] = amount
