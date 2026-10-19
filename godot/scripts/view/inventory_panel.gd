class_name InventoryPanel
extends VBoxContainer

const DISPLAY_RES := [
	"GOLD",
	"BOARDS",
	"FOOD",
	"TOOLS",
	"BRICKS",
	"CLAY",
]

var _title: Label
var _rows: Dictionary = {} # res_name -> Label
var _extra_grid: GridContainer


func _ready() -> void:
	_title = Label.new()
	_title.text = "Inventory"
	add_child(_title)
	var main_grid := GridContainer.new()
	main_grid.columns = 2
	add_child(main_grid)
	for res_name in DISPLAY_RES:
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex := ResourceIconRegistry.get_icon_for_res_name(res_name)
		if tex != null:
			icon.texture = tex
		row.add_child(icon)
		var label := Label.new()
		label.text = "%s: —" % res_name
		row.add_child(label)
		main_grid.add_child(row)
		_rows[res_name] = label
	_extra_grid = GridContainer.new()
	_extra_grid.columns = 2
	_extra_grid.name = "ExtraResources"
	add_child(_extra_grid)


func show_inventory(title: String, inventory: Inventory) -> void:
	_title.text = title
	_clear_extra_grid()
	if inventory == null:
		for res_name in DISPLAY_RES:
			_rows[res_name].text = "%s: —" % res_name
		return
	for res_name in DISPLAY_RES:
		var res_id: int = GameConstants.RES[res_name]
		_rows[res_name].text = "%s: %d" % [res_name, inventory.amount(res_id)]
	for res_name in GameConstants.RES.keys():
		if res_name in DISPLAY_RES:
			continue
		var rid := int(GameConstants.RES[res_name])
		var amt := inventory.amount(rid)
		if amt <= 0:
			continue
		_add_extra_row(res_name, amt)


func _clear_extra_grid() -> void:
	for child in _extra_grid.get_children():
		child.queue_free()


func _add_extra_row(res_name: String, amount: int) -> void:
	var row := HBoxContainer.new()
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var tex := ResourceIconRegistry.get_icon_for_res_name(res_name)
	if tex != null:
		icon.texture = tex
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s: %d" % [res_name, amount]
	row.add_child(label)
	_extra_grid.add_child(row)
