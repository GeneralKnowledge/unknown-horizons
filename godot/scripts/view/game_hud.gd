class_name GameHud
extends Label

var session: GameSession
var selected: Building


func bind(p_session: GameSession) -> void:
	session = p_session


func set_selected(building: Building) -> void:
	selected = building
	refresh()


func refresh() -> void:
	if session == null:
		text = "Unknown Horizons Godot"
		return
	var settlement := session.settlement
	var lines: PackedStringArray = []
	lines.append("Unknown Horizons Godot — Settlement Loop")
	lines.append(
		"Settlement gold: %d  buildings: %d  tick: %d"
		% [
			settlement.inventory.amount(GameConstants.RES["GOLD"]),
			settlement.buildings.size(),
			session.scheduler.cur_tick,
		]
	)
	if selected != null:
		var inv := selected.get_storage()
		var state_name := "—"
		var producer := selected.get_producer()
		if producer != null:
			state_name = ProductionStates.name_for(producer._get_current_state())
		lines.append(
			"Selected trees:%d boards:%d state:%s"
			% [
				inv.amount(GameConstants.RES["TREES"]),
				inv.amount(GameConstants.RES["BOARDS"]),
				state_name,
			]
		)
	else:
		lines.append("Click to place building (BuildTool)")
	text = "\n".join(lines)
