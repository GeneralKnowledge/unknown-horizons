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
var _rows: Dictionary = {}


func _ready() -> void:
	_title = Label.new()
	_title.text = "Inventory"
	add_child(_title)
	for res_name in DISPLAY_RES:
		var row := Label.new()
		row.text = "%s: —" % res_name
		add_child(row)
		_rows[res_name] = row


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
