class_name BuildPalettePanel
extends VBoxContainer

signal mode_selected(mode: StringName)

var _build_tool: BuildTool
var _status: Label
var _legend: Label
var _pending_bind: BuildTool = null
var _tabs: TabContainer
var _tear_row: HBoxContainer


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
	_legend = Label.new()
	_legend.text = "Ghost: green = valid, red = invalid"
	add_child(_legend)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.custom_minimum_size = Vector2(0, 120)
	add_child(_tabs)
	_tear_row = HBoxContainer.new()
	add_child(_tear_row)
	var tear_btn := Button.new()
	tear_btn.text = "Tear"
	tear_btn.pressed.connect(func(): _apply_mode(&"tear"))
	_tear_row.add_child(tear_btn)
	if _pending_bind != null:
		_build_tool = _pending_bind
		_pending_bind = null
	if _build_tool != null:
		_rebuild()


func _rebuild() -> void:
	for child in _tabs.get_children():
		child.queue_free()
	if _build_tool == null:
		return
	var menu := _load_full_menu()
	if menu.get("tabs", []).is_empty():
		_add_poc_tab()
	else:
		for tab in menu.get("tabs", []):
			if typeof(tab) != TYPE_DICTIONARY:
				continue
			var scroll := ScrollContainer.new()
			scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var col := VBoxContainer.new()
			scroll.add_child(col)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for section in tab.get("sections", []):
				if typeof(section) != TYPE_DICTIONARY:
					continue
				var hdr := Label.new()
				hdr.text = str(section.get("label", "Buildings"))
				col.add_child(hdr)
				var row := HBoxContainer.new()
				col.add_child(row)
				for stem in section.get("stems", []):
					row.add_child(_stem_button(str(stem)))
			var tab_id := str(tab.get("id", "tab"))
			_tabs.add_child(scroll)
			_tabs.set_tab_title(_tabs.get_tab_count() - 1, tab_id)
	_refresh_status()


func _add_poc_tab() -> void:
	var scroll := ScrollContainer.new()
	var row := HBoxContainer.new()
	scroll.add_child(row)
	for stem in _load_poc_stems():
		row.add_child(_stem_button(str(stem)))
	_tabs.add_child(scroll)
	_tabs.set_tab_title(0, "PoC")


func _stem_button(label: String, cb: Callable = Callable()) -> Button:
	var btn := Button.new()
	if label == "Tear":
		btn.text = "Tear"
	else:
		var bid := _building_id_for_stem(label)
		var icon := BuildingVisualRegistry.get_palette_icon_for_building(bid, 28)
		if icon != null:
			btn.icon = icon
			btn.expand_icon = true
		btn.text = ContentTheme.label_for_build_stem(label)
		btn.tooltip_text = _build_cost_tooltip(label)
	if cb.is_valid():
		btn.pressed.connect(cb)
	else:
		var captured := label
		btn.pressed.connect(func(): _apply_stem(captured))
	return btn


func _load_full_menu() -> Dictionary:
	const FULL_MENU := "res://resources/exported/build_menu.json"
	if not FileAccess.file_exists(FULL_MENU):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FULL_MENU))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


func _load_poc_stems() -> Array:
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
	_try_first_click_audio()


func _build_cost_tooltip(stem: String) -> String:
	var building_id := _building_id_for_stem(stem)
	var costs := BuildingCosts.costs_for_building_id(building_id)
	if costs.is_empty():
		return "No settlement cost"
	var parts: PackedStringArray = []
	for res_id in costs.keys():
		var need: int = int(costs[res_id])
		var label := _resource_label(int(res_id))
		parts.append("%s: %d" % [label, need])
	return "Cost: %s" % ", ".join(parts)


func _resource_label(res_id: int) -> String:
	for name in GameConstants.RES:
		if int(GameConstants.RES[name]) == res_id:
			return name.to_lower().replace("_", " ")
	return "res_%d" % res_id


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
		_status.text = "Build: %s" % ContentTheme.label_for_build_stem(stem)


func _try_first_click_audio() -> void:
	if has_meta("_audio_primed"):
		return
	set_meta("_audio_primed", true)
	GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")
