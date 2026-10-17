class_name StartMenuPanel
extends PanelContainer

signal new_game_requested
signal continue_requested
signal showcase_requested
signal import_save_file(path: String)

var _import_dialog: FileDialog


func _ready() -> void:
	custom_minimum_size = Vector2(320, 220)
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
	v.add_child(_btn("Play showcase demo", func(): showcase_requested.emit()))
	v.add_child(_btn("New game", func(): new_game_requested.emit()))
	var continue_btn := _btn("Continue", func(): continue_requested.emit())
	continue_btn.disabled = not FileAccess.file_exists(SaveLoadPanel.DEFAULT_SAVE_PATH)
	v.add_child(continue_btn)
	v.add_child(_btn("Import save…", func(): _import_dialog.popup_centered()))
	_import_dialog = FileDialog.new()
	_import_dialog.title = "Import save"
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	var filters := PackedStringArray(["*.json ; JSON snapshots"])
	if not OS.has_feature("web"):
		filters.append("*.sqlite ; Legacy SQLite saves")
		filters.append("*.sqlite.bz2 ; Compressed legacy saves")
	_import_dialog.filters = filters
	_import_dialog.size = Vector2i(640, 480)
	_import_dialog.file_selected.connect(_on_import_file)
	add_child(_import_dialog)


func _btn(label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(cb)
	return b


func _on_import_file(path: String) -> void:
	if not path.is_empty():
		import_save_file.emit(path)
