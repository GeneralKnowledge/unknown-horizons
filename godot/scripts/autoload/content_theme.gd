extends Node

## Optional UI theme / content pack labels (sim ids unchanged).

const ACTIVE_THEME_PATH := "res://resources/exported/active_theme.json"
const PACK_ROOT := "res://resources/dlc/"

const UI_LABELS_SCHEMA_VERSION := 1

var pack_id: String = ""
var display_name: String = ""
var gfx_root: String = ""
var player_accent_color: String = ""
var ui_theme_id: String = ""
var hud_status_ok_color: String = ""
var hud_status_error_color: String = ""

var _legacy_sound_overrides: Dictionary = {}
var _label_overrides: Dictionary = {}
var _ui_theme: Theme


func _ready() -> void:
	_reload()


func _reload() -> void:
	pack_id = ""
	display_name = ""
	gfx_root = ""
	player_accent_color = ""
	ui_theme_id = ""
	hud_status_ok_color = ""
	hud_status_error_color = ""
	_legacy_sound_overrides = {}
	_label_overrides = {}
	_ui_theme = null
	if not FileAccess.file_exists(ACTIVE_THEME_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ACTIVE_THEME_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	pack_id = str(data.get("pack_id", "")).strip_edges()
	_apply_active_theme_overrides(data)
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
	if player_accent_color.is_empty():
		player_accent_color = str(manifest.get("player_accent_color", ""))
	ui_theme_id = str(manifest.get("ui_theme", ""))
	var sounds_file := str(manifest.get("sounds_manifest", "sounds.json"))
	var sounds_path := "%s%s/%s" % [PACK_ROOT, pack_id, sounds_file]
	if FileAccess.file_exists(sounds_path):
		var sounds: Variant = JSON.parse_string(FileAccess.get_file_as_string(sounds_path))
		if typeof(sounds) == TYPE_DICTIONARY:
			_legacy_sound_overrides = sounds
	_label_overrides = load_ui_labels_for_pack(pack_id)


func _apply_active_theme_overrides(active: Dictionary) -> void:
	var hud: Dictionary = active.get("hud", {})
	if typeof(hud) != TYPE_DICTIONARY:
		return
	player_accent_color = str(hud.get("accent_color", player_accent_color))
	hud_status_ok_color = str(hud.get("status_ok_color", ""))
	hud_status_error_color = str(hud.get("status_error_color", ""))


static func parse_ui_labels_file(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	if data.has("labels") and typeof(data.get("labels")) == TYPE_DICTIONARY:
		var version := int(data.get("schema_version", UI_LABELS_SCHEMA_VERSION))
		if version > UI_LABELS_SCHEMA_VERSION:
			push_warning("ContentTheme: ui_labels schema v%d newer than supported" % version)
		return data.get("labels", {}).duplicate()
	# Legacy flat stem → label map
	var out := {}
	for key in data.keys():
		if key.begins_with("_") or key == "schema_version":
			continue
		out[key] = data[key]
	return out


static func load_ui_labels_for_pack(p_pack_id: String) -> Dictionary:
	if p_pack_id.is_empty():
		return {}
	var labels_path := "%s%s/ui_labels.json" % [PACK_ROOT, p_pack_id]
	if not FileAccess.file_exists(labels_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(labels_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parse_ui_labels_file(parsed)


func _normalize_gfx_root(path: String) -> String:
	if path.is_empty():
		return ""
	if path.begins_with("res://"):
		return path.rstrip("/")
	if path.begins_with("godot/"):
		return ("res://" + path.trim_prefix("godot/")).rstrip("/")
	return ("res://resources/dlc/%s/gfx" % pack_id).rstrip("/")


func label_for_build_stem(stem: String) -> String:
	if _label_overrides.has(stem):
		return str(_label_overrides[stem])
	return stem


func legacy_audio_res_for_key(manifest_key: String) -> String:
	if _legacy_sound_overrides.has(manifest_key):
		return str(_legacy_sound_overrides[manifest_key])
	return ""


func get_ui_theme() -> Theme:
	if _ui_theme != null:
		return _ui_theme
	if pack_id.is_empty() or ui_theme_id.is_empty():
		return null
	var path := "%s%s/themes/%s.tres" % [PACK_ROOT, pack_id, ui_theme_id]
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Theme:
			_ui_theme = loaded
	return _ui_theme


func hud_accent_color() -> Color:
	return _parse_hex_color(player_accent_color, Color(0.92, 0.95, 1.0))


func hud_status_ok() -> Color:
	return _parse_hex_color(hud_status_ok_color, Color(0.85, 1.0, 0.85))


func hud_status_error() -> Color:
	return _parse_hex_color(hud_status_error_color, Color(1.0, 0.35, 0.35))


func _parse_hex_color(hex: String, fallback: Color) -> Color:
	var s := hex.strip_edges()
	if s.is_empty():
		return fallback
	if not s.begins_with("#"):
		s = "#" + s
	return Color.from_string(s, fallback)
