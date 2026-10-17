extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _hud: GameHud = $CanvasLayer/HUD
@onready var _building_layer: Node2D = $BuildingLayer
@onready var _ghost: Sprite2D = $GhostSprite
@onready var _camera: Camera2D = $Camera2D

var _session: GameSession
var _build_tool: BuildTool
var _context_manager: ViewContextManager
var _views: Dictionary = {}
var _sim_clock := SimClock.new()
var _hover_grid := Vector2i.ZERO
var _map_id: String = DemoConfig.default_map_id()
var _camera_ctrl: MapCameraController
var _start_menu: StartMenuPanel
var _game_active := false
var _audio_primed := false


func _ready() -> void:
	DemoConfig.apply_theme_pack_if_configured()
	_camera_ctrl = MapCameraController.new()
	add_child(_camera_ctrl)
	_camera_ctrl.setup(_camera, _map_view)
	_camera_ctrl.set_ui_blocker(_is_pointer_over_hud)
	_setup_start_menu()
	if DemoConfig.show_start_menu():
		_show_start_menu()
	else:
		_begin_new_game()


func _setup_start_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StartMenuLayer"
	layer.layer = 10
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	_start_menu = StartMenuPanel.new()
	center.add_child(_start_menu)
	_start_menu.new_game_requested.connect(_on_start_new_game)
	_start_menu.continue_requested.connect(_on_start_continue)
	_start_menu.import_save_file.connect(_on_import_save_file)
	_start_menu.showcase_requested.connect(_on_showcase_requested)
	_start_menu.visible = false
	layer.visible = false
	layer.name = "StartMenuLayer"


func _show_start_menu() -> void:
	_game_active = false
	var layer := get_node_or_null("StartMenuLayer")
	if layer:
		layer.visible = true
	_start_menu.visible = true


func _hide_start_menu() -> void:
	var layer := get_node_or_null("StartMenuLayer")
	if layer:
		layer.visible = false
	_start_menu.visible = false
	_game_active = true


func _begin_new_game() -> void:
	_session = GameSession.new()
	_boot_map(_map_id)
	GameTestHelpers.new_settlement(_session, DemoConfig.default_settlement_point())
	_wire_gameplay()
	_hide_start_menu()
	_camera_ctrl.fit_island()
	_hud.show_status("New game on map %s" % _map_id)


func _wire_gameplay() -> void:
	_build_tool = BuildTool.new(_session)
	if _build_tool.building_placed.is_connected(_on_building_placed):
		_build_tool.building_placed.disconnect(_on_building_placed)
	_build_tool.building_placed.connect(_on_building_placed)
	if _context_manager == null:
		_context_manager = ViewContextManager.new()
		add_child(_context_manager)
	_context_manager.setup(_session, _build_tool, _map_view)
	if not _context_manager.context_changed.is_connected(_on_context_changed):
		_context_manager.context_changed.connect(_on_context_changed)
	_map_view.bind(_session.island)
	_hud.bind(_session, _build_tool)
	_hud.bind_context(_context_manager)
	if not _hud.map_selected.is_connected(_on_map_selected):
		_hud.map_selected.connect(_on_map_selected)
	if not _hud.context_selected.is_connected(_context_manager.set_context):
		_hud.context_selected.connect(_context_manager.set_context)
	if not _hud.build_mode_selected.is_connected(_on_build_palette_mode):
		_hud.build_mode_selected.connect(_on_build_palette_mode)
	if not _hud.save_requested.is_connected(_on_save_requested):
		_hud.save_requested.connect(_on_save_requested)
	if not _hud.load_requested.is_connected(_on_load_requested):
		_hud.load_requested.connect(_on_load_requested)
	if not _hud.import_snapshot.is_connected(_on_import_snapshot):
		_hud.import_snapshot.connect(_on_import_snapshot)
	if not _hud.import_save_file.is_connected(_on_import_save_file):
		_hud.import_save_file.connect(_on_import_save_file)
	if not MessageBus.building_placed.is_connected(_on_bus_building_placed):
		MessageBus.building_placed.connect(_on_bus_building_placed)
	_hud.refresh()
	_update_ghost()
	for child in _building_layer.get_children():
		child.queue_free()
	_views.clear()


func _on_start_new_game() -> void:
	_begin_new_game()


func _on_start_continue() -> void:
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	if _load_snapshot_text(text):
		_hide_start_menu()
		_camera_ctrl.fit_island()


func _process(delta: float) -> void:
	if not _game_active or _session == null:
		return
	_sim_clock.accumulate_and_run(_session, delta, func():
		MessageBus.settlement_updated.emit()
		for view in _views.values():
			if view is BuildingView:
				(view as BuildingView).refresh_from_sim()
	)
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_active:
		return
	if event is InputEventMouseMotion:
		_hover_grid = _map_view.screen_to_grid(event.position)
		_update_ghost()
	if _context_manager != null:
		_context_manager.process_input(event)
	if event is InputEventMouseButton and event.pressed:
		_prime_audio()
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				_context_manager.set_context(&"select")
			KEY_B:
				_context_manager.set_context(&"build")
			KEY_T:
				_context_manager.set_context(&"tear")


func _prime_audio() -> void:
	if _audio_primed:
		return
	_audio_primed = true
	GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")


func _is_pointer_over_hud() -> bool:
	var mp := get_viewport().get_mouse_position()
	return _hud.get_global_rect().has_point(mp)


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
	if _session == null:
		return
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	var snap := _session.to_snapshot()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_hud.show_status("Save failed: could not write user://", true)
		return
	file.store_string(JSON.stringify(snap, "\t"))
	file.close()
	_hud.show_status("Saved to user://")


func _on_load_requested() -> void:
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	if not FileAccess.file_exists(path):
		_hud.show_status("No save in user://", true)
		return
	var text := FileAccess.get_file_as_string(path)
	_load_snapshot_text(text)


func _on_import_snapshot(json_text: String) -> void:
	if _load_snapshot_text(json_text):
		_hide_start_menu()
		_camera_ctrl.fit_island()


func _on_import_save_file(path: String) -> void:
	if path.ends_with(".json"):
		var text := FileAccess.get_file_as_string(path)
		if text.is_empty():
			_hud.show_status("Empty save file", true)
			return
		_on_import_snapshot(text)
		return
	if SqliteSaveLoader.is_sqlite_file(path):
		_on_import_sqlite(path)
		return
	_hud.show_status("Unsupported save format", true)


func _on_import_sqlite(path: String) -> void:
	if OS.has_feature("web"):
		_hud.show_status("Legacy SQLite import is desktop-only; use JSON", true)
		return
	var result := SqliteSaveLoader.load_with_report(path)
	if not result["ok"]:
		_hud.show_status("SQLite import failed: %s" % str(result.get("error", "")), true)
		return
	var loaded: GameSession = result["session"]
	var report: SqliteImportReport = result["report"]
	_apply_session(loaded)
	_map_id = report.map_id if not report.map_id.is_empty() else _map_id
	_hide_start_menu()
	_camera_ctrl.fit_island()
	var msg := "Legacy save: %d/%d buildings" % [report.buildings_placed, report.buildings_extracted]
	if report.partial:
		msg += " (partial)"
	_hud.show_status(msg)


func _on_showcase_requested() -> void:
	var scenario_path := DemoConfig.showcase_scenario_path()
	var scenario := DemoScenarioRunner.load_dict(scenario_path)
	if scenario.is_empty():
		_hud.show_status("Showcase scenario missing", true)
		return
	_map_id = str(scenario.get("map_id", DemoConfig.default_map_id()))
	_session = DemoScenarioRunner.boot_from_dict(scenario, 30.0)
	if _session == null:
		_hud.show_status("Showcase failed to start", true)
		return
	if _build_tool == null:
		_wire_gameplay()
	else:
		_apply_session(_session)
	_hide_start_menu()
	_camera_ctrl.fit_island()
	_hud.show_status("Showcase demo — tier-1 economy")


func _load_snapshot_text(json_text: String) -> bool:
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		_hud.show_status("Invalid save JSON", true)
		return false
	if _session == null:
		_session = GameSession.new()
		_boot_map(_map_id)
		_wire_gameplay()
	var before := _session.get_buildings_on_island(_session.island).size()
	var result := _session.try_load_snapshot(data)
	if not result["ok"]:
		_hud.show_status("Load failed: %s" % str(result.get("error", "")), true)
		if _session.get_buildings_on_island(_session.island).size() != before:
			push_error("Session mutated after failed load")
		return false
	_apply_session(_session)
	_hud.show_status("Save loaded")
	return true


func _boot_map(map_id: String) -> void:
	_map_id = map_id
	MapLoader.apply_map_to_session(_session, map_id)


func _on_map_selected(map_id: String) -> void:
	_boot_map(map_id)
	_map_view.bind(_session.island)
	_camera_ctrl.fit_island()
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
	if new_session == null:
		_hud.show_status("Load failed: empty session", true)
		return
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
	if not _game_active or _build_tool == null:
		_ghost.visible = false
		return
	_ghost.position = _map_view.grid_to_screen(_hover_grid)
	if _build_tool.can_place_at(_hover_grid):
		_ghost.modulate = Color(0.3, 0.9, 0.3, 0.55)
	else:
		_ghost.modulate = Color(0.9, 0.2, 0.2, 0.55)
	var ctx := &"build"
	if _context_manager != null:
		ctx = _context_manager.get_context_name()
	_ghost.visible = ctx != &"select" and _build_tool.active
