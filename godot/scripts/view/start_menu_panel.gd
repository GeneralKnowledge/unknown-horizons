class_name StartMenuPanel
extends PanelContainer

signal new_game_requested
signal continue_requested
signal showcase_requested
signal import_save_file(path: String)

var _import_json_dialog: FileDialog
var _import_legacy_dialog: FileDialog


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
	var continue_btn := _btn("Continue JSON save", func(): continue_requested.emit())
	continue_btn.disabled = not FileAccess.file_exists(SaveLoadPanel.DEFAULT_SAVE_PATH)
	v.add_child(continue_btn)
	v.add_child(_btn("Import JSON save…", func(): _import_json_dialog.popup_centered()))
	var legacy_btn := _btn("Import legacy SQLite…", func(): _import_legacy_dialog.popup_centered())
	if OS.has_feature("web"):
		legacy_btn.disabled = true
		legacy_btn.tooltip_text = "Legacy .sqlite import is desktop-only. Use JSON saves in the browser."
	v.add_child(legacy_btn)
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
			+ "(buildings + inventories only; not full campaign parity). "
			+ "Prefer JSON for the settlement demo."
		)
	v.add_child(note)
	_import_json_dialog = _make_import_dialog(
		"Import JSON save",
		PackedStringArray(["*.json ; JSON snapshots"])
	)
	_import_legacy_dialog = _make_import_dialog(
		"Import legacy SQLite save",
		PackedStringArray(["*.sqlite ; Legacy SQLite saves", "*.sqlite.bz2 ; Compressed legacy saves"])
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


func _on_import_file(path: String) -> void:
	if not path.is_empty():
		import_save_file.emit(path)
