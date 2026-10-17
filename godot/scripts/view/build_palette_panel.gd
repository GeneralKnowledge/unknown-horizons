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
	var stems: Array = _load_menu_stems()
	for stem in stems:
		var btn := Button.new()
		btn.text = ContentTheme.label_for_build_stem(str(stem))
		var captured: String = str(stem)
		btn.pressed.connect(func():
			_apply_stem(captured)
		)
		add_child(btn)
	var tear_btn := Button.new()
	tear_btn.text = "Tear"
	tear_btn.pressed.connect(func(): _apply_mode(&"tear"))
	add_child(tear_btn)
	_refresh_status()


func _load_menu_stems() -> Array:
	const FULL_MENU := "res://resources/exported/build_menu.json"
	if FileAccess.file_exists(FULL_MENU):
		var full: Variant = JSON.parse_string(FileAccess.get_file_as_string(FULL_MENU))
		if typeof(full) == TYPE_DICTIONARY:
			var stems: Array = []
			for tab in full.get("tabs", []):
				if typeof(tab) != TYPE_DICTIONARY:
					continue
				for section in tab.get("sections", []):
					if typeof(section) != TYPE_DICTIONARY:
						continue
					for stem in section.get("stems", []):
						if not stems.has(stem):
							stems.append(stem)
			if not stems.is_empty():
				return stems
	const MENU_PATH := "res://resources/exported/poc_build_menu.json"
	if not FileAccess.file_exists(MENU_PATH):
		return ["lumberjackcamp", "tree"]
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MENU_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return ["lumberjackcamp", "tree"]
	return data.get("stems", ["lumberjackcamp", "tree"])


func _apply_stem(stem: String) -> void:
	if _build_tool == null:
		return
	_build_tool.tear_mode = false
	_build_tool.building_id = _building_id_for_stem(stem)
	mode_selected.emit(StringName(stem))
	_refresh_status()


func _building_id_for_stem(stem: String) -> int:
	for key in GameConstants.BUILDINGS.keys():
		var id: int = int(GameConstants.BUILDINGS[key])
		if ContentLoader.stem_for_building_id(id) == stem:
			return id
	push_warning("Unknown build menu stem %s" % stem)
	return GameConstants.BUILDINGS["LUMBERJACK"]


func _apply_mode(mode: StringName) -> void:
	if _build_tool == null:
		return
	match mode:
		&"tear":
			_build_tool.set_palette_tear()
		_:
			_apply_stem(str(mode))
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
