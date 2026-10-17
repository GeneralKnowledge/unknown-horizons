extends Node

## Optional UI theme / content pack labels (sim ids unchanged).

const ACTIVE_THEME_PATH := "res://resources/exported/active_theme.json"
const PACK_ROOT := "res://resources/dlc/"

var pack_id: String = ""
var display_name: String = ""


func _ready() -> void:
	_reload()


func _reload() -> void:
	pack_id = ""
	display_name = ""
	if not FileAccess.file_exists(ACTIVE_THEME_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ACTIVE_THEME_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	pack_id = str(data.get("pack_id", "")).strip_edges()
	if pack_id.is_empty():
		return
	var manifest_path := "%s%s/manifest.json" % [PACK_ROOT, pack_id]
	if not FileAccess.file_exists(manifest_path):
		push_warning("ContentTheme: unknown pack %s" % pack_id)
		pack_id = ""
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	display_name = str(manifest.get("display_name", pack_id))


func label_for_build_stem(stem: String) -> String:
	if pack_id.is_empty():
		return stem
	var labels_path := "%s%s/ui_labels.json" % [PACK_ROOT, pack_id]
	if not FileAccess.file_exists(labels_path):
		return stem
	var labels: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(labels_path))
	if labels.has(stem):
		return str(labels[stem])
	return stem
