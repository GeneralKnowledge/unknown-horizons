class_name GameHud
extends MarginContainer

var session: GameSession
var selected: Building

@onready var _header: Label = $VBox/Header
@onready var _settlement_panel: InventoryPanel = $VBox/SettlementInventory
@onready var _building_panel: InventoryPanel = $VBox/BuildingInventory
@onready var _producer_label: Label = $VBox/ProducerState
@onready var _palette: BuildPalettePanel = $VBox/BuildPalette


func bind(p_session: GameSession, build_tool: BuildTool = null) -> void:
	session = p_session
	if build_tool != null:
		_palette.bind(build_tool)
	if not MessageBus.settlement_updated.is_connected(refresh):
		MessageBus.settlement_updated.connect(refresh)
	if not MessageBus.building_placed.is_connected(_on_building_placed):
		MessageBus.building_placed.connect(_on_building_placed)
	if not MessageBus.building_removed.is_connected(refresh):
		MessageBus.building_removed.connect(refresh)
	if not MessageBus.building_selected.is_connected(_on_building_selected):
		MessageBus.building_selected.connect(_on_building_selected)


func _on_building_placed(building: Building) -> void:
	set_selected(building)


func _on_building_selected(building: Building) -> void:
	set_selected(building)


func set_selected(building: Building) -> void:
	selected = building
	refresh()


func refresh() -> void:
	if session == null:
		_header.text = "Unknown Horizons Godot"
		return
	var settlement := session.settlement
	_header.text = (
		"Settlement — gold: %d  buildings: %d  tick: %d"
		% [
			settlement.inventory.amount(GameConstants.RES["GOLD"]),
			settlement.buildings.size(),
			session.scheduler.cur_tick,
		]
	)
	_settlement_panel.show_inventory("Settlement warehouse", settlement.inventory)
	if selected != null:
		var inv := selected.get_storage()
		var stem := ContentLoader.stem_for_building_id(selected.building_id)
		_building_panel.show_inventory("Selected: %s" % stem, inv)
		var producer := selected.get_producer()
		if producer != null:
			_producer_label.text = "Producer: %s" % ProductionStates.name_for(
				producer._get_current_state()
			)
		else:
			_producer_label.text = "Producer: —"
	else:
		_building_panel.show_inventory("Selected building", null)
		_producer_label.text = "Left-click: place  |  Right-click: select"
