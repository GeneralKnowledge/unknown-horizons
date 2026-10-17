class_name StartMenuPanel
extends PanelContainer

signal new_game_requested
signal continue_requested
signal import_snapshot(json_text: String)

var _import_dialog: FileDialog


func _ready() -> void:
	custom_minimum_size = Vector2(320, 220)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = DemoConfig.title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(_btn("New game", func(): new_game_requested.emit()))
	v.add_child(_btn("Continue", func(): continue_requested.emit()))
	v.add_child(_btn("Import save…", func(): _import_dialog.popup_centered()))
	_import_dialog = FileDialog.new()
	_import_dialog.title = "Import save"
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.filters = PackedStringArray(["*.json ; JSON saves"])
	_import_dialog.size = Vector2i(640, 480)
	_import_dialog.file_selected.connect(_on_import_file)
	add_child(_import_dialog)


func _btn(label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(cb)
	return b


func _on_import_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if not text.is_empty():
		import_snapshot.emit(text)
