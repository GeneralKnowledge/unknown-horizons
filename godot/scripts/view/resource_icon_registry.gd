extends Node

## Maps GameConstants.RES ids to 32px icons (from upstream godot-port).

const ICON_ROOT := "res://resources/upstream/godot-port/icons/resources/32/"

## Same subset as inventory HUD rows (avoid preload order issues with InventoryPanel).
const DISPLAY_RES := [
	"GOLD",
	"BOARDS",
	"FOOD",
	"TOOLS",
	"BRICKS",
	"CLAY",
]

var _texture_by_res_id: Dictionary = {}


func _ready() -> void:
	_preload_display_icons()


func _preload_display_icons() -> void:
	for res_name in DISPLAY_RES:
		var res_id: int = int(GameConstants.RES[res_name])
		var path := _icon_path_for_id(res_id)
		if FileAccess.file_exists(path):
			_texture_by_res_id[res_id] = load(path) as Texture2D


func get_icon_for_res_id(res_id: int) -> Texture2D:
	if _texture_by_res_id.has(res_id):
		return _texture_by_res_id[res_id] as Texture2D
	var path := _icon_path_for_id(res_id)
	if FileAccess.file_exists(path):
		var tex := load(path) as Texture2D
		_texture_by_res_id[res_id] = tex
		return tex
	return null


func get_icon_for_res_name(res_name: String) -> Texture2D:
	if not GameConstants.RES.has(res_name):
		return null
	return get_icon_for_res_id(int(GameConstants.RES[res_name]))


static func _icon_path_for_id(res_id: int) -> String:
	return "%s%03d.png" % [ICON_ROOT, res_id]
