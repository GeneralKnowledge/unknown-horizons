class_name StartMenuPanel
extends PanelContainer

signal new_game_requested
signal continue_requested
signal showcase_requested
signal import_save_file(path: String)

var _import_json_dialog: FileDialog
var _import_legacy_dialog: FileDialog
var _continue_btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(360, 280)
	var pack_theme := ContentTheme.get_ui_theme()
	if pack_theme != null:
		theme = pack_theme
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = DemoConfig.title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var subtitle := DemoConfig.subtitle()
	if not subtitle.is_empty():
		var sub := Label.new()
		sub.text = subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sub)
	var goal := Label.new()
	goal.text = (
		"Prototype goal: establish a lumber camp, deliver boards to the warehouse, "
		+ "then build a brickyard and deliver bricks."
	)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(goal)
	v.add_child(_btn("Start settlement demo", func(): new_game_requested.emit()))
	v.add_child(_btn("Economy showcase (pre-built)", func(): showcase_requested.emit()))
	_continue_btn = _btn("Continue JSON save", func(): continue_requested.emit())
	v.add_child(_continue_btn)
	refresh_continue_availability()
	v.add_child(_btn("Import JSON save…", func(): _import_json_dialog.popup_centered()))
	if OS.has_feature("web"):
		v.add_child(
			_btn(
				"Import legacy extract (.extract.json)…",
				func(): _import_legacy_dialog.popup_centered()
			)
		)
	else:
		v.add_child(_btn("Import legacy SQLite…", func(): _import_legacy_dialog.popup_centered()))
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if OS.has_feature("web"):
		note.text = (
			"Browser: JSON saves only (Save / Download in the HUD). "
			+ "Legacy Unknown Horizons saves are not supported on the web."
		)
	else:
		note.text = (
			"Legacy Unknown Horizons .sqlite / .sqlite.bz2: partial restore "
			+ "(buildings, storage, production, collectors, settler meta, in-flight collector jobs; "
			+ "ships as placeholders). "
			+ "Prefer JSON for the settlement demo."
		)
	v.add_child(note)
	_import_json_dialog = _make_import_dialog(
		"Import JSON save",
		PackedStringArray(["*.json ; JSON snapshots"])
	)
	if OS.has_feature("web"):
		_import_legacy_dialog = _make_import_dialog(
			"Import legacy extract bundle",
			PackedStringArray(["*.extract.json ; Prebuilt legacy extract bundles"])
		)
	else:
		_import_legacy_dialog = _make_import_dialog(
			"Import legacy SQLite save",
			PackedStringArray([
				"*.sqlite ; Legacy SQLite saves",
				"*.sqlite.bz2 ; Compressed legacy saves",
				"*.extract.json ; Prebuilt legacy extract bundles",
			])
		)
	add_child(_import_json_dialog)
	add_child(_import_legacy_dialog)


func _make_import_dialog(title: String, filters: PackedStringArray) -> FileDialog:
	var dlg := FileDialog.new()
	dlg.title = title
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.filters = filters
	dlg.size = Vector2i(640, 480)
	dlg.file_selected.connect(_on_import_file)
	return dlg


func _btn(label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(cb)
	return b


func refresh_continue_availability() -> void:
	if _continue_btn == null:
		return
	var has_save := FileAccess.file_exists(SaveLoadPanel.DEFAULT_SAVE_PATH)
	_continue_btn.disabled = not has_save
	_continue_btn.tooltip_text = (
		"Loads user://poc_snapshot.json (settlement demo progress when saved from the HUD)."
		if has_save
		else "Play the demo and use Save JSON in the HUD, or Import JSON save."
	)


func _on_import_file(path: String) -> void:
	if not path.is_empty():
		import_save_file.emit(path)
