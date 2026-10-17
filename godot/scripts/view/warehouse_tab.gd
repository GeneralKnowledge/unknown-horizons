class_name WarehouseTab
extends VBoxContainer

var session: GameSession
var selected: Building

var _info: Label
var _transfer_boards: Button


func _ready() -> void:
	_info = Label.new()
	_info.text = "Warehouse actions"
	add_child(_info)
	_transfer_boards = Button.new()
	_transfer_boards.text = "Transfer 5 boards → settlement"
	_transfer_boards.pressed.connect(_on_transfer_boards)
	add_child(_transfer_boards)


func bind(p_session: GameSession) -> void:
	session = p_session


func set_selected(building: Building) -> void:
	selected = building
	_refresh()


func _refresh() -> void:
	if selected == null:
		_info.text = "Select a production building"
		_transfer_boards.disabled = true
		return
	var stem := ContentLoader.stem_for_building_id(selected.building_id)
	var boards := selected.get_storage().amount(GameConstants.RES["BOARDS"])
	_info.text = "%s — boards in building: %d" % [stem, boards]
	_transfer_boards.disabled = boards <= 0


func _on_transfer_boards() -> void:
	if session == null or selected == null:
		return
	session.manager.execute(
		TransferToSettlementCommand.new(selected, GameConstants.RES["BOARDS"], 5)
	)
	_refresh()
