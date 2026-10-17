extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _hud: GameHud = $CanvasLayer/HUD
@onready var _building_layer: Node2D = $BuildingLayer
@onready var _ghost: Sprite2D = $GhostSprite

var _session: GameSession
var _build_tool: BuildTool
var _context_manager: ViewContextManager
var _views: Dictionary = {} # worldid -> BuildingView
var _sim_clock := SimClock.new()
var _hover_grid := Vector2i.ZERO
var _map_id: String = MapLoader.default_map_id()


func _ready() -> void:
	_session = GameSession.new()
	_boot_map(_map_id)
	GameTestHelpers.new_settlement(_session, TestMapFactory.default_settlement_point())
	_build_tool = BuildTool.new(_session)
	_build_tool.building_placed.connect(_on_building_placed)
	_context_manager = ViewContextManager.new()
	add_child(_context_manager)
	_context_manager.setup(_session, _build_tool, _map_view)
	_context_manager.context_changed.connect(_on_context_changed)
	_map_view.bind(_session.island)
	_hud.bind(_session, _build_tool)
	_hud.bind_context(_context_manager)
	_hud.map_selected.connect(_on_map_selected)
	_hud.context_selected.connect(_context_manager.set_context)
	_hud.build_mode_selected.connect(_on_build_palette_mode)
	_hud.refresh()
	_update_ghost()
	if not MessageBus.building_placed.is_connected(_on_bus_building_placed):
		MessageBus.building_placed.connect(_on_bus_building_placed)
	if not _hud.save_requested.is_connected(_on_save_requested):
		_hud.save_requested.connect(_on_save_requested)
	if not _hud.load_requested.is_connected(_on_load_requested):
		_hud.load_requested.connect(_on_load_requested)
	if not _hud.import_snapshot.is_connected(_on_import_snapshot):
		_hud.import_snapshot.connect(_on_import_snapshot)


func _process(delta: float) -> void:
	_sim_clock.accumulate_and_run(_session, delta, func():
		MessageBus.settlement_updated.emit()
		for view in _views.values():
			if view is BuildingView:
				(view as BuildingView).refresh_from_sim()
	)
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_grid = _map_view.screen_to_grid(event.position)
		_update_ghost()
	if _context_manager != null:
		_context_manager.process_input(event)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_context_manager.set_context(&"build")
				_build_tool.set_palette_lumberjack()
			KEY_2:
				_context_manager.set_context(&"build")
				_build_tool.set_palette_tree()
			KEY_3, KEY_T:
				_context_manager.set_context(&"tear")
			KEY_S:
				_context_manager.set_context(&"select")
			KEY_B:
				_context_manager.set_context(&"build")


func _on_building_placed(building: Building) -> void:
	_attach_view(building)


func _on_bus_building_placed(building: Building) -> void:
	if not _views.has(building.worldid):
		_attach_view(building)


func _attach_view(building: Building) -> void:
	var view := BuildingView.new()
	_building_layer.add_child(view)
	view.bind(building, _map_view)
	_views[building.worldid] = view


func _on_save_requested() -> void:
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	var snap := _session.to_snapshot()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save to %s" % path)
		return
	file.store_string(JSON.stringify(snap, "\t"))
	file.close()


func _on_load_requested() -> void:
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	if not FileAccess.file_exists(path):
		push_warning("No save at %s" % path)
		return
	var loaded := JsonSnapshotLoader.load_from_file(path)
	_apply_session(loaded)


func _on_import_snapshot(json_text: String) -> void:
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid save JSON")
		return
	_apply_session(JsonSnapshotLoader.load_from_dict(data))


func _boot_map(map_id: String) -> void:
	_map_id = map_id
	MapLoader.apply_map_to_session(_session, map_id)


func _on_map_selected(map_id: String) -> void:
	_boot_map(map_id)
	_map_view.bind(_session.island)
	_update_ghost()


func _on_context_changed(context_name: StringName) -> void:
	_hud.set_context_name(context_name)
	_update_ghost()


func _on_build_palette_mode(mode: StringName) -> void:
	if mode == &"tear":
		_context_manager.set_context(&"tear")
	else:
		_context_manager.set_context(&"build")


func _apply_session(new_session: GameSession) -> void:
	_session = new_session
	_sim_clock.reset()
	_build_tool = BuildTool.new(_session)
	_build_tool.building_placed.connect(_on_building_placed)
	_context_manager.setup(_session, _build_tool, _map_view)
	_map_view.bind(_session.island)
	_hud.bind(_session, _build_tool)
	for child in _building_layer.get_children():
		child.queue_free()
	_views.clear()
	for b in _session.get_buildings_on_island(_session.island):
		_attach_view(b)
	_hud.refresh()
	_update_ghost()


func _update_ghost() -> void:
	_ghost.position = _map_view.grid_to_screen(_hover_grid)
	if _build_tool.can_place_at(_hover_grid):
		_ghost.modulate = Color(0.3, 0.9, 0.3, 0.55)
	else:
		_ghost.modulate = Color(0.9, 0.2, 0.2, 0.55)
	var ctx := &"build"
	if _context_manager != null:
		ctx = _context_manager.get_context_name()
	_ghost.visible = ctx != &"select" and _build_tool.active
