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
var _map_picker: MapPickerPanel
var _context_panel: ContextModePanel
var _production: ProductionOverviewPanel

signal save_requested
signal load_requested
signal import_snapshot(json_text: String)
signal map_selected(map_id: String)
signal context_selected(context_name: StringName)
signal build_mode_selected(mode: StringName)

@onready var _hint: Label = $VBox/GameplayHint
@onready var _status: Label = $VBox/StatusLine

var _status_timer: float = 0.0


func _ready() -> void:
	_apply_pack_theme()


func _apply_pack_theme() -> void:
	var pack_theme := ContentTheme.get_ui_theme()
	if pack_theme != null:
		theme = pack_theme


func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0 and _status != null:
			_status.text = ""


func show_status(message: String, is_error: bool = false) -> void:
	if _status == null:
		return
	_status.text = message
	_status.modulate = ContentTheme.hud_status_error() if is_error else ContentTheme.hud_status_ok()
	_status_timer = 5.0


func bind(p_session: GameSession, build_tool: BuildTool = null) -> void:
	session = p_session
	if build_tool != null:
		_palette.bind(build_tool)
		if not _palette.mode_selected.is_connected(_on_palette_mode):
			_palette.mode_selected.connect(_on_palette_mode)
	_warehouse.bind(p_session)
	if _production != null:
		_production.bind(p_session)
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
	if OS.is_debug_build() and _map_picker == null:
		_map_picker = MapPickerPanel.new()
		$VBox.add_child(_map_picker)
		$VBox.move_child(_map_picker, 1)
		if not _map_picker.map_selected.is_connected(_on_map_picker):
			_map_picker.map_selected.connect(_on_map_picker)
	if _context_panel == null:
		_context_panel = ContextModePanel.new()
		$VBox.add_child(_context_panel)
		$VBox.move_child(_context_panel, _palette.get_index())
		if not _context_panel.context_selected.is_connected(_on_context_panel):
			_context_panel.context_selected.connect(_on_context_panel)
	if _production == null:
		_production = ProductionOverviewPanel.new()
		$VBox.add_child(_production)
		$VBox.move_child(_production, _palette.get_index() + 1)
func bind_context(context_manager: ViewContextManager) -> void:
	if _context_panel != null:
		_context_panel.highlight(context_manager.get_context_name())


func set_context_name(context_name: StringName) -> void:
	if _context_panel != null:
		_context_panel.highlight(context_name)


func _on_map_picker(map_id: String) -> void:
	map_selected.emit(map_id)


func _on_context_panel(context_name: StringName) -> void:
	context_selected.emit(context_name)


func _on_palette_mode(mode: StringName) -> void:
	build_mode_selected.emit(mode)


func _on_building_placed(building: Building) -> void:
	set_selected(building)


func _on_building_selected(building: Building) -> void:
	set_selected(building)


func set_selected(building: Building) -> void:
	selected = building
	_warehouse.set_selected(building)
	if _production != null:
		_production.set_selected(building)
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
	if ContentTheme.pack_id != "":
		_header.modulate = ContentTheme.hud_accent_color()
	else:
		_header.modulate = Color.WHITE
	if _hint != null:
		_hint.text = "Pan: middle-drag | Zoom: wheel | Build palette tabs below"
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
		if _production != null:
			_production.set_selected(selected)
	else:
		_building_panel.show_inventory("Selected building", null)
		_producer_label.text = "Use mode buttons or B / S / T keys"
