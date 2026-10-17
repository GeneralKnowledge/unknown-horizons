class_name ScenarioRunner
extends RefCounted

const _ParityTrace = preload("res://scripts/parity/parity_trace.gd")
const TICKS_PER_SECOND := 16

var _scenario: Dictionary = {}
var _gts: GameTestSession
var _last_building: Building


func _read_text(path: String) -> String:
	var fs_path := path
	if path.begins_with("res://"):
		fs_path = ProjectSettings.globalize_path(path)
	var f := FileAccess.open(fs_path, FileAccess.READ)
	if f == null and fs_path != path:
		f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Could not read scenario at %s (globalized %s)" % [path, fs_path])
		return ""
	return f.get_as_text()


func run_file(scenario_path: String) -> Dictionary:
	var text := _read_text(scenario_path)
	var data: Variant = JSON.parse_string(text)
	assert(typeof(data) == TYPE_DICTIONARY, "Scenario must be a JSON object")
	_scenario = data
	_boot_session()
	for step in _scenario.get("steps", []):
		_execute_step(step)
	var scenario_id: String = str(_scenario.get("id", "unknown"))
	return _ParityTrace.from_session(_gts.session, scenario_id)


func _boot_session() -> void:
	_gts = GameTestSession.new()
	_gts.session = GameSession.new()
	_gts.session.load_test_map()
	var spec := _map_spec()
	var settle_xy: Array = spec["settlement"]["godot"]
	var settled := GameTestHelpers.new_settlement(
		_gts.session, Vector2i(int(settle_xy[0]), int(settle_xy[1]))
	)
	_gts.session.settlement = settled.settlement
	for res_name in spec.get("starting_resources", {}).keys():
		var amount := int(spec["starting_resources"][res_name])
		_gts.session.settlement.inventory.alter(
			int(GameConstants.RES[str(res_name)]), amount
		)
	_gts.player = SimPlayer.new(_gts.session.allocate_worldid(), _gts.session.settlement)


func _map_spec() -> Dictionary:
	var text := FileAccess.get_file_as_string("res://resources/parity/map_specs.json")
	var all: Variant = JSON.parse_string(text)
	var map_id: String = str(_scenario.get("map", "test_island_20x20"))
	return all[map_id]


func _execute_step(step: Dictionary) -> void:
	var op: String = str(step.get("op", ""))
	match op:
		"settle":
			pass
		"build":
			var bid := int(GameConstants.BUILDINGS[str(step["building"])])
			_last_building = _gts.build(bid, int(step["x"]), int(step["y"]))
		"build_ownerless":
			var bid2 := int(GameConstants.BUILDINGS[str(step["building"])])
			_last_building = _gts.build_ownerless(bid2, int(step["x"]), int(step["y"]))
		"build_farm":
			var fields: Array = []
			for f in step.get("fields", []):
				fields.append(int(GameConstants.BUILDINGS[str(f)]))
			_last_building = _gts.build_farm(int(step["x"]), int(step["y"]), fields)
		"alter_storage":
			var res_id := int(GameConstants.RES[str(step["resource"])])
			var amount := int(step["amount"])
			if str(step.get("target", "building")) == "settlement":
				_gts.session.settlement.inventory.alter(res_id, amount)
			else:
				assert(_last_building != null)
				_last_building.get_storage().alter(res_id, amount)
		"run_ticks":
			_gts.run_ticks(int(step["ticks"]))
		"run_seconds":
			_gts.run_seconds(float(step["seconds"]))
		"toggle_producer":
			assert(_last_building != null)
			var producer := _last_building.get_producer()
			if producer != null:
				if step.has("active") and not bool(step["active"]):
					producer.set_all_active(false)
				else:
					producer.toggle_active()
		"snapshot_roundtrip":
			_gts.session = _gts.snapshot_roundtrip()
		_:
			push_error("Unknown parity op: %s" % op)
