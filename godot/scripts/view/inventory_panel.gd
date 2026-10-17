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
var _rows: Dictionary = {} # res_name -> HBoxContainer


func _ready() -> void:
	_title = Label.new()
	_title.text = "Inventory"
	add_child(_title)
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
		add_child(row)
		_rows[res_name] = label


func show_inventory(title: String, inventory: Inventory) -> void:
	_title.text = title
	if inventory == null:
		for res_name in DISPLAY_RES:
			_rows[res_name].text = "%s: —" % res_name
		return
	for res_name in DISPLAY_RES:
		var res_id: int = GameConstants.RES[res_name]
		var amount := inventory.amount(res_id)
		if amount > 0 or res_name in ["GOLD", "BOARDS", "FOOD"]:
			_rows[res_name].text = "%s: %d" % [res_name, amount]
		else:
			_rows[res_name].text = "%s: 0" % res_name
