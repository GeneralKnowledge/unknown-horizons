class_name WarehouseTab
extends VBoxContainer

var session: GameSession
var selected: Building

var _info: Label
var _transfer_row: HBoxContainer
var _custom_row: HBoxContainer
var _amount_spin: SpinBox
var _custom_res: OptionButton


const TRANSFER_OPTIONS: Array = [
	{"res": "BOARDS", "amount": 5},
	{"res": "BRICKS", "amount": 2},
	{"res": "TOOLS", "amount": 1},
]

const CUSTOM_RES: Array = ["BOARDS", "BRICKS", "TOOLS", "FOOD", "TEXTILE"]


func _ready() -> void:
	_info = Label.new()
	_info.text = "Warehouse actions"
	add_child(_info)
	_transfer_row = HBoxContainer.new()
	add_child(_transfer_row)
	for opt in TRANSFER_OPTIONS:
		var res_name: String = opt["res"]
		var amount: int = opt["amount"]
		var btn := Button.new()
		btn.text = "→ settlement %d %s" % [amount, res_name.to_lower()]
		btn.pressed.connect(func(): _transfer(res_name, amount))
		_transfer_row.add_child(btn)
	_custom_row = HBoxContainer.new()
	add_child(_custom_row)
	_custom_res = OptionButton.new()
	for res_name in CUSTOM_RES:
		_custom_res.add_item(res_name)
	_custom_row.add_child(_custom_res)
	_amount_spin = SpinBox.new()
	_amount_spin.min_value = 1
	_amount_spin.max_value = 999
	_amount_spin.value = 5
	_custom_row.add_child(_amount_spin)
	var custom_btn := Button.new()
	custom_btn.text = "Transfer amount → settlement"
	custom_btn.pressed.connect(_on_custom_transfer)
	_custom_row.add_child(custom_btn)


func bind(p_session: GameSession) -> void:
	session = p_session


func set_selected(building: Building) -> void:
	selected = building
	_refresh()


func _refresh() -> void:
	if selected == null:
		_info.text = "Select a production building"
		for btn in _transfer_row.get_children():
			if btn is Button:
				(btn as Button).disabled = true
		_custom_row.visible = false
		return
	var stem := ContentLoader.stem_for_building_id(selected.building_id)
	_info.text = "%s — move goods to settlement warehouse" % stem
	for btn in _transfer_row.get_children():
		if btn is Button:
			(btn as Button).disabled = false
	_custom_row.visible = true


func _on_custom_transfer() -> void:
	var idx := _custom_res.selected
	if idx < 0 or idx >= CUSTOM_RES.size():
		return
	_transfer(CUSTOM_RES[idx], int(_amount_spin.value))


func _transfer(res_name: String, amount: int) -> void:
	if session == null or selected == null:
		return
	if not GameConstants.RES.has(res_name):
		return
	var res_id := int(GameConstants.RES[res_name])
	var moved: int = session.manager.execute(
		TransferToSettlementCommand.new(selected, res_id, amount)
	)
	if moved > 0:
		MessageBus.logbook_entry.emit("Transferred %d %s to settlement" % [moved, res_name.to_lower()])
		_refresh()
	else:
		MessageBus.build_feedback.emit("Nothing to transfer", true)
