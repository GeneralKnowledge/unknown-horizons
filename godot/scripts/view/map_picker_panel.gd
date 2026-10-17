class_name MapPickerPanel
extends HBoxContainer

signal map_selected(map_id: String)

var _option: OptionButton


func _ready() -> void:
	var label := Label.new()
	label.text = "Map:"
	add_child(label)
	_option = OptionButton.new()
	_option.item_selected.connect(_on_item_selected)
	add_child(_option)
	_reload()


func _reload() -> void:
	_option.clear()
	var maps: Array = MapLoader.list_maps()
	if maps.is_empty():
		_option.add_item("Default", 0)
		_option.set_item_metadata(0, MapLoader.default_map_id())
		return
	for i in range(maps.size()):
		var entry: Dictionary = maps[i]
		var id: String = str(entry.get("id", MapLoader.default_map_id()))
		var name: String = str(entry.get("name", id))
		_option.add_item(name, i)
		_option.set_item_metadata(i, id)


func _on_item_selected(index: int) -> void:
	var map_id: String = str(_option.get_item_metadata(index))
	map_selected.emit(map_id)
