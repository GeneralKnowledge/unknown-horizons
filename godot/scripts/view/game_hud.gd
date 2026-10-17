class_name GameHud
extends MarginContainer

var session: GameSession
var selected: Building

@onready var _header: Label = $VBox/Header
@onready var _settlement_panel: InventoryPanel = $VBox/SettlementInventory
@onready var _building_panel: InventoryPanel = $VBox/BuildingInventory
@onready var _producer_label: Label = $VBox/ProducerState
@onready var _palette: BuildPalettePanel = $VBox/BuildPalette
@onready var _warehouse: WarehouseTab = $VBox/WarehouseTab

var _save_load: SaveLoadPanel
var _dev_debug: DevDebugPanel

signal save_requested
signal load_requested
signal import_snapshot(json_text: String)

@onready var _hint: Label = $VBox/GameplayHint


func bind(p_session: GameSession, build_tool: BuildTool = null) -> void:
	session = p_session
	if build_tool != null:
		_palette.bind(build_tool)
	_warehouse.bind(p_session)
	if not MessageBus.settlement_updated.is_connected(refresh):
		MessageBus.settlement_updated.connect(refresh)
	if not MessageBus.building_placed.is_connected(_on_building_placed):
		MessageBus.building_placed.connect(_on_building_placed)
	if not MessageBus.building_removed.is_connected(refresh):
		MessageBus.building_removed.connect(refresh)
	if not MessageBus.building_selected.is_connected(_on_building_selected):
		MessageBus.building_selected.connect(_on_building_selected)
	if _save_load == null:
		_save_load = SaveLoadPanel.new()
		$VBox.add_child(_save_load)
		_save_load.save_requested.connect(func(): save_requested.emit())
		_save_load.load_requested.connect(func(): load_requested.emit())
		_save_load.export_save_requested.connect(func(): export_snapshot_text(_snapshot_text_for_export()))
		_save_load.import_snapshot.connect(func(t): import_snapshot.emit(t))
	if OS.is_debug_build():
		if _dev_debug == null:
			_dev_debug = DevDebugPanel.new()
			$VBox.add_child(_dev_debug)
		_dev_debug.bind(p_session)


func _on_building_placed(building: Building) -> void:
	set_selected(building)


func _on_building_selected(building: Building) -> void:
	set_selected(building)


func set_selected(building: Building) -> void:
	selected = building
	_warehouse.set_selected(building)
	if _dev_debug != null:
		_dev_debug.set_selected(building)
	refresh()


func export_snapshot_text(json_text: String) -> void:
	if _save_load != null:
		_save_load.export_snapshot_to_disk_or_browser(json_text)


func _snapshot_text_for_export() -> String:
	if session == null:
		return ""
	return JSON.stringify(session.to_snapshot(), "\t")


func refresh() -> void:
	if session == null:
		_header.text = "Unknown Horizons Godot"
		return
	var settlement := session.settlement
	var theme_suffix := ""
	if ContentTheme.display_name != "":
		theme_suffix = "  [%s]" % ContentTheme.display_name
	_header.text = (
		"Settlement — gold: %d  buildings: %d  tick: %d%s"
		% [
			settlement.inventory.amount(GameConstants.RES["GOLD"]),
			settlement.buildings.size(),
			session.scheduler.cur_tick,
			theme_suffix,
		]
	)
	if _hint != null:
		_hint.text = (
			"Loop: place lumberjack → place trees nearby → wait for boards → save/load or download JSON."
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
