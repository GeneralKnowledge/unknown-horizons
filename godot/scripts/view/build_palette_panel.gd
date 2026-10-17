class_name BuildPalettePanel
extends HBoxContainer

signal mode_selected(mode: StringName)

var _build_tool: BuildTool
var _status: Label
var _pending_bind: BuildTool = null


func bind(p_tool: BuildTool) -> void:
	_build_tool = p_tool
	if is_node_ready():
		_rebuild()
	else:
		_pending_bind = p_tool


func _ready() -> void:
	_status = Label.new()
	_status.text = "Build: —"
	add_child(_status)
	if _pending_bind != null:
		_build_tool = _pending_bind
		_pending_bind = null
	if _build_tool != null:
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		if child != _status:
			child.queue_free()
	if _build_tool == null:
		return
	var modes := [
		["Lumberjack", "lumberjack"],
		["Tree", "tree"],
		["Tear", "tear"],
	]
	for entry in modes:
		var btn := Button.new()
		btn.text = entry[0]
		var mode: StringName = StringName(entry[1])
		btn.pressed.connect(func():
			_apply_mode(mode)
		)
		add_child(btn)
	_refresh_status()


func _apply_mode(mode: StringName) -> void:
	if _build_tool == null:
		return
	match mode:
		&"lumberjack":
			_build_tool.set_palette_lumberjack()
		&"tree":
			_build_tool.set_palette_tree()
		&"tear":
			_build_tool.set_palette_tear()
	mode_selected.emit(mode)
	_refresh_status()


func _refresh_status() -> void:
	if _build_tool == null:
		_status.text = "Build: —"
		return
	if _build_tool.tear_mode:
		_status.text = "Build: Tear (click building tile)"
	else:
		var stem := ContentLoader.stem_for_building_id(_build_tool.building_id)
		_status.text = "Build: %s" % stem
