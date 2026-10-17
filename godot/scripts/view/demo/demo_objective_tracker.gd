class_name DemoObjectiveTracker
extends RefCounted

signal objective_completed
signal state_changed

const DEMO_SNAPSHOT_KEY := "playable_lumber"

var session: GameSession
var target_boards: int = 8
var min_trees: int = 2
var completed: bool = false
var _completion_emitted := false


func _init(p_session: GameSession = null) -> void:
	session = p_session
	target_boards = PlayableDemoConfig.target_boards()
	min_trees = PlayableDemoConfig.min_trees()


func bind_session(p_session: GameSession) -> void:
	session = p_session
	_completion_emitted = false
	state_changed.emit()


func reset_for_new_game() -> void:
	completed = false
	_completion_emitted = false
	state_changed.emit()


func apply_snapshot_demo_block(demo: Dictionary) -> void:
	var block: Variant = demo.get(DEMO_SNAPSHOT_KEY, {})
	if typeof(block) != TYPE_DICTIONARY:
		return
	completed = bool(block.get("completed", false))
	_completion_emitted = completed
	state_changed.emit()


func to_snapshot_demo_block() -> Dictionary:
	return {
		DEMO_SNAPSHOT_KEY: {
			"completed": completed,
			"target_boards": target_boards,
			"min_trees": min_trees,
		},
	}


func lumberjack_count() -> int:
	return _count_building(GameConstants.BUILDINGS["LUMBERJACK"])


func tree_count() -> int:
	return _count_building(GameConstants.BUILDINGS["TREE"])


func warehouse_boards() -> int:
	if session == null:
		return 0
	return session.settlement.inventory.amount(GameConstants.RES["BOARDS"])


func objective_title() -> String:
	if completed:
		return "Objective complete — building materials delivered"
	return "Deliver %d boards to the settlement warehouse" % target_boards


func hint_text() -> String:
	if completed:
		return "Keep building or save your progress. Menu: restart from title screen."
	if lumberjack_count() < 1:
		return "Open Build (B), choose Lumberjack, and place it inside the settlement area."
	if tree_count() < min_trees:
		return "Plant %d trees near the camp so the lumberjack can harvest." % min_trees
	if warehouse_boards() < target_boards:
		var have := warehouse_boards()
		return (
			"Let production run — collectors haul boards to the warehouse (%d / %d)."
			% [have, target_boards]
		)
	return "Delivery threshold reached."


func progress_line() -> String:
	return "Camp: %d  Trees: %d  Warehouse boards: %d / %d" % [
		lumberjack_count(),
		tree_count(),
		warehouse_boards(),
		target_boards,
	]


func tick_after_sim() -> void:
	if session == null or completed:
		return
	if lumberjack_count() < 1:
		return
	if tree_count() < min_trees:
		return
	if warehouse_boards() >= target_boards:
		completed = true
		state_changed.emit()
		if not _completion_emitted:
			_completion_emitted = true
			objective_completed.emit()


func _count_building(building_id: int) -> int:
	if session == null:
		return 0
	var n := 0
	for b in session.get_buildings_on_island(session.island):
		if b.building_id == building_id:
			n += 1
	return n
