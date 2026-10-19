class_name DemoObjectiveTracker
extends RefCounted

signal objective_completed
signal step_advanced(step_index: int)
signal state_changed

var session: GameSession
var steps: Array = []
var current_step_index: int = 0
var completed: bool = false
var _completion_emitted := false


func _init(p_session: GameSession = null) -> void:
	session = p_session
	steps = PlayableDemoConfig.steps()


func bind_session(p_session: GameSession) -> void:
	session = p_session
	_completion_emitted = false
	state_changed.emit()


func reset_for_new_game() -> void:
	current_step_index = 0
	completed = false
	_completion_emitted = false
	steps = PlayableDemoConfig.steps()
	state_changed.emit()


func apply_snapshot_demo_block(demo: Dictionary) -> void:
	PlayableDemoConfig.set_profile_from_snapshot(demo)
	steps = PlayableDemoConfig.steps()
	var key := PlayableDemoConfig.snapshot_key()
	var block: Variant = demo.get(key, {})
	if typeof(block) != TYPE_DICTIONARY:
		return
	current_step_index = int(block.get("current_step_index", 0))
	completed = bool(block.get("completed", false))
	_completion_emitted = completed
	state_changed.emit()


func to_snapshot_demo_block() -> Dictionary:
	var key := PlayableDemoConfig.snapshot_key()
	return {
		"profile": "expedition" if key == "playable_northern_expedition" else "short",
		key: {
			"completed": completed,
			"current_step_index": current_step_index,
			"step_count": steps.size(),
		},
	}


func current_step() -> Dictionary:
	if steps.is_empty():
		return {}
	if current_step_index >= steps.size():
		return steps[steps.size() - 1]
	return steps[current_step_index]


func objective_title() -> String:
	if completed:
		return "Northern expedition complete — all deliveries met"
	var step := current_step()
	if step.is_empty():
		return "Settlement objective"
	if step.has("title"):
		return "Step %d — %s" % [current_step_index + 1, str(step.get("title"))]
	var res_name := str(step.get("resource", "BOARDS"))
	var amount := int(step.get("warehouse_amount", 1))
	return "Step %d — Deliver %d %s to the warehouse" % [
		current_step_index + 1, amount, res_name.to_lower()
	]


func hint_text() -> String:
	if completed:
		return PlayableDemoConfig.success_message()
	var step := current_step()
	if step.is_empty():
		return ""
	if step.has("hint"):
		return str(step.get("hint"))
	var step_id := str(step.get("id", ""))
	if step_id == "boards":
		return _hint_boards_step(step)
	if step_id == "bricks":
		return _hint_bricks_step(step)
	if step_id == "food":
		return _hint_food_step(step)
	if step_id == "tools":
		return "Build a toolmaker, keep boards in settlement stock, then wait for tools in the warehouse."
	if step_id == "textile":
		return "Build a weaver tent; it consumes textiles inputs from your economy — deliver cloth to the warehouse."
	if step_id.begins_with("dlc_"):
		return "Northern Company building from the build menu (DLC tab); shared settlement inventory."
	return "Follow the objective panel and map markers."


func _hint_boards_step(step: Dictionary) -> String:
	if lumberjack_count() < 1:
		return "Build (B) → lumberjack camp. Costs come from settlement stock (gold, tools)."
	var min_trees := int(step.get("min_trees", 2))
	if tree_count() < min_trees:
		return "Plant %d trees near the camp (each tree costs gold)." % min_trees
	var target := int(step.get("warehouse_amount", 8))
	var have := _warehouse_amount(str(step.get("resource", "BOARDS")))
	return "Production runs automatically; collectors haul goods (%d / %d in warehouse)." % [
		have, target
	]


func _hint_bricks_step(step: Dictionary) -> String:
	var required: Array = step.get("require_buildings", [])
	if GameConstants.BUILDINGS["CLAY_PIT"] in _required_ids(required) and clay_pit_count() < 1:
		return "Build a clay pit on the clay deposit (marked on the island)."
	if GameConstants.BUILDINGS["BRICKYARD"] in _required_ids(required) and brickyard_count() < 1:
		return "Build a brickyard inside the settlement — needs boards and tools from stock."
	var target := int(step.get("warehouse_amount", 4))
	var have := _warehouse_amount(str(step.get("resource", "BRICKS")))
	return "Run the clay → brick chain; collectors move bricks to the warehouse (%d / %d)." % [
		have, target
	]


func _hint_food_step(step: Dictionary) -> String:
	var any: Array = step.get("require_any_buildings", [])
	if not any.is_empty() and not _any_building_present(any):
		return "Build a hunter camp or fisher hut (food chain)."
	var target := int(step.get("warehouse_amount", 6))
	var have := _warehouse_amount("FOOD")
	return "Keep production running; food lands in the warehouse (%d / %d)." % [have, target]


func step_label_short() -> String:
	if completed:
		if PlayableDemoConfig.snapshot_key() == "playable_northern_expedition":
			return "expedition complete"
		return "demo complete"
	if steps.is_empty():
		return "demo"
	return "step %d/%d" % [current_step_index + 1, steps.size()]


func progress_line() -> String:
	var step := current_step()
	if step.is_empty():
		return ""
	var res := str(step.get("resource", "BOARDS"))
	var target := int(step.get("warehouse_amount", 0))
	var have := _warehouse_amount(res)
	var extra := ""
	var step_id := str(step.get("id", ""))
	if step_id == "boards":
		extra = "  Camp: %d  Trees: %d" % [lumberjack_count(), tree_count()]
	elif step_id == "bricks":
		extra = "  Pit: %d  Brickyard: %d" % [clay_pit_count(), brickyard_count()]
	elif step_id == "food":
		extra = "  Hunter: %d  Fisher: %d" % [hunter_count(), fisher_count()]
	elif step_id == "tools":
		extra = "  Toolmaker: %d" % toolmaker_count()
	elif step_id == "textile":
		extra = "  Weaver: %d" % weaver_count()
	elif step_id.begins_with("dlc_"):
		extra = "  Smokery: %d  Tower: %d" % [dlc_count("NORTHERN_SMOKERY"), dlc_count("NORTHERN_SIGNAL_TOWER")]
	return "Warehouse %s: %d / %d%s" % [res.to_lower(), have, target, extra]


func tick_after_sim() -> void:
	if session == null or completed:
		return
	while current_step_index < steps.size():
		if not _step_requirements_met(current_step()):
			return
		var target_res := str(current_step().get("resource", "BOARDS"))
		var need := int(current_step().get("warehouse_amount", 1))
		if _warehouse_amount(target_res) < need:
			return
		current_step_index += 1
		step_advanced.emit(current_step_index)
		state_changed.emit()
	if current_step_index >= steps.size() and not completed:
		completed = true
		state_changed.emit()
		if not _completion_emitted:
			_completion_emitted = true
			objective_completed.emit()


func _step_requirements_met(step: Dictionary) -> bool:
	if step.is_empty():
		return false
	var step_id := str(step.get("id", ""))
	if step_id == "boards":
		if bool(step.get("require_lumberjack", true)) and lumberjack_count() < 1:
			return false
		if tree_count() < int(step.get("min_trees", 2)):
			return false
	for name in step.get("require_buildings", []):
		if _count_by_name(str(name)) < 1:
			return false
	var any: Variant = step.get("require_any_buildings", [])
	if typeof(any) == TYPE_ARRAY and not any.is_empty():
		if not _any_building_present(any):
			return false
	if step_id == "bricks":
		for bid in _required_ids(step.get("require_buildings", [])):
			if _count_building(bid) < 1:
				return false
	return true


func _any_building_present(names: Array) -> bool:
	for name in names:
		if _count_by_name(str(name)) >= 1:
			return true
	return false


func _required_ids(required: Variant) -> Array:
	var out: Array = []
	if typeof(required) != TYPE_ARRAY:
		return out
	for name in required:
		var id := _building_id_for_name(str(name))
		if id >= 0:
			out.append(id)
	return out


func _building_id_for_name(name: String) -> int:
	if GameConstants.BUILDINGS.has(name):
		return int(GameConstants.BUILDINGS[name])
	if DlcConstants.BUILDINGS.has(name):
		return int(DlcConstants.BUILDINGS[name])
	return -1


func _count_by_name(name: String) -> int:
	var id := _building_id_for_name(name)
	if id < 0:
		return 0
	return _count_building(id)


func _warehouse_amount(res_name: String) -> int:
	if session == null or not GameConstants.RES.has(res_name):
		return 0
	return session.settlement.inventory.amount(int(GameConstants.RES[res_name]))


func lumberjack_count() -> int:
	return _count_building(GameConstants.BUILDINGS["LUMBERJACK"])


func tree_count() -> int:
	return _count_building(GameConstants.BUILDINGS["TREE"])


func clay_pit_count() -> int:
	return _count_building(GameConstants.BUILDINGS["CLAY_PIT"])


func brickyard_count() -> int:
	return _count_building(GameConstants.BUILDINGS["BRICKYARD"])


func hunter_count() -> int:
	return _count_building(GameConstants.BUILDINGS["HUNTER"])


func fisher_count() -> int:
	return _count_building(GameConstants.BUILDINGS["FISHER"])


func toolmaker_count() -> int:
	return _count_building(GameConstants.BUILDINGS["TOOLMAKER"])


func weaver_count() -> int:
	return _count_building(GameConstants.BUILDINGS["WEAVER"])


func dlc_count(name: String) -> int:
	return _count_by_name(name)


func _count_building(building_id: int) -> int:
	if session == null:
		return 0
	var n := 0
	for b in session.get_buildings_on_island(session.island):
		if b.building_id == building_id:
			n += 1
	return n
