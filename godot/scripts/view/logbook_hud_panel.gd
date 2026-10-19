class_name LogbookHudPanel
extends PanelContainer

const MAX_LINES := 40

var _list: ItemList


func _ready() -> void:
	custom_minimum_size = Vector2(280, 80)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "Logbook"
	v.add_child(title)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(260, 72)
	_list.auto_height = true
	v.add_child(_list)
	if not MessageBus.logbook_entry.is_connected(_append):
		MessageBus.logbook_entry.connect(_append)


func _append(message: String) -> void:
	if _list == null:
		return
	_list.add_item(message)
	while _list.item_count > MAX_LINES:
		_list.remove_item(0)
