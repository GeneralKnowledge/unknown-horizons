class_name SaveLoadPanel
extends HBoxContainer

signal save_requested
signal load_requested
signal export_save_requested
signal import_snapshot(json_text: String)

const DEFAULT_SAVE_PATH := "user://poc_snapshot.json"

var _import_dialog: FileDialog
var _export_dialog: FileDialog


func _ready() -> void:
	_add_button("Save JSON", func(): save_requested.emit())
	_add_button("Load JSON", func(): load_requested.emit())
	_add_button("Download save", func(): export_save_requested.emit())
	_add_button("Import save", func(): _open_import_dialog())
	_import_dialog = FileDialog.new()
	_import_dialog.title = "Import save"
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.filters = PackedStringArray(["*.json ; JSON saves"])
	_import_dialog.size = Vector2i(600, 400)
	_import_dialog.file_selected.connect(_on_import_file_selected)
	add_child(_import_dialog)
	if not OS.has_feature("web"):
		_export_dialog = FileDialog.new()
		_export_dialog.title = "Export save"
		_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_export_dialog.filters = PackedStringArray(["*.json ; JSON saves"])
		_export_dialog.size = Vector2i(600, 400)
		_export_dialog.file_selected.connect(_on_export_file_selected)
		add_child(_export_dialog)


func _add_button(label: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(cb)
	add_child(btn)


func _open_import_dialog() -> void:
	_import_dialog.popup_centered()


func _on_import_file_selected(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Empty save file: %s" % path)
		return
	import_snapshot.emit(text)


func export_snapshot_to_disk_or_browser(json_text: String) -> void:
	if json_text.is_empty():
		return
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(
			json_text.to_utf8_buffer(), "uh_godot_snapshot.json", "application/json"
		)
	elif _export_dialog != null:
		_pending_export_text = json_text
		_export_dialog.popup_centered()
	else:
		push_error("Export dialog unavailable")


var _pending_export_text := ""


func _on_export_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % path)
		return
	file.store_string(_pending_export_text)
	file.close()
	_pending_export_text = ""
