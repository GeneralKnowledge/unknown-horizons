extends Node

## Optional UI theme / content pack labels (sim ids unchanged).

const ACTIVE_THEME_PATH := "res://resources/exported/active_theme.json"
const PACK_ROOT := "res://resources/dlc/"

var pack_id: String = ""
var display_name: String = ""
var gfx_root: String = ""
var player_accent_color: String = ""
var ui_theme_id: String = ""

var _legacy_sound_overrides: Dictionary = {}


func _ready() -> void:
	_reload()


func _reload() -> void:
	pack_id = ""
	display_name = ""
	gfx_root = ""
	player_accent_color = ""
	ui_theme_id = ""
	_legacy_sound_overrides = {}
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
	gfx_root = _normalize_gfx_root(str(manifest.get("gfx_root", "")))
	player_accent_color = str(manifest.get("player_accent_color", ""))
	ui_theme_id = str(manifest.get("ui_theme", ""))
	var sounds_file := str(manifest.get("sounds_manifest", "sounds.json"))
	var sounds_path := "%s%s/%s" % [PACK_ROOT, pack_id, sounds_file]
	if FileAccess.file_exists(sounds_path):
		var sounds: Variant = JSON.parse_string(FileAccess.get_file_as_string(sounds_path))
		if typeof(sounds) == TYPE_DICTIONARY:
			_legacy_sound_overrides = sounds


func _normalize_gfx_root(path: String) -> String:
	if path.is_empty():
		return ""
	if path.begins_with("res://"):
		return path
	if path.begins_with("godot/"):
		return "res://" + path.trim_prefix("godot/")
	return "res://resources/dlc/%s/gfx" % pack_id


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


func legacy_audio_res_for_key(manifest_key: String) -> String:
	if _legacy_sound_overrides.has(manifest_key):
		return str(_legacy_sound_overrides[manifest_key])
	return ""
