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
var _playable_demo := false
var _sim_paused := false
var _objective_tracker: DemoObjectiveTracker
var _demo_world_hints: DemoWorldHints
var _success_panel: DemoSuccessPanel
var _success_layer: CanvasLayer
var _selected_worldid: int = -1
var _screenshot_out := ""
var _screenshot_preset := ""
var _screenshot_frames := 0
var _video_slice := ""
var _video_duration := 28.0
var _video_time := 0.0
var _video_flags: Dictionary = {}
var _collector_layer: CollectorViewLayer

const SCREENSHOT_WARMUP_FRAMES := 14


func _ready() -> void:
	DemoConfig.apply_theme_pack_if_configured()
	_camera_ctrl = MapCameraController.new()
	add_child(_camera_ctrl)
	_camera_ctrl.setup(_camera, _map_view)
	_camera_ctrl.set_ui_blocker(_is_pointer_over_hud)
	_parse_capture_cmdline()
	_setup_start_menu()
	if not _screenshot_preset.is_empty():
		_bootstrap_screenshot_preset()
		return
	if not _video_slice.is_empty():
		_bootstrap_video_slice()
		return
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
	_start_menu.expedition_requested.connect(_on_expedition_requested)
	_start_menu.visible = false
	layer.visible = false
	layer.name = "StartMenuLayer"


func _show_start_menu() -> void:
	_game_active = false
	var layer := get_node_or_null("StartMenuLayer")
	if layer:
		layer.visible = true
	_start_menu.visible = true
	_start_menu.refresh_continue_availability()


func _hide_start_menu() -> void:
	var layer := get_node_or_null("StartMenuLayer")
	if layer:
		layer.visible = false
	_start_menu.visible = false
	_game_active = true


func _begin_new_game() -> void:
	PlayableDemoConfig.use_short_demo()
	_start_playable_settlement_demo()


func _on_expedition_requested() -> void:
	PlayableDemoConfig.use_expedition_demo()
	_start_playable_settlement_demo()
	_hud.show_status("Northern expedition — 8 delivery milestones")


func _start_playable_settlement_demo() -> void:
	_playable_demo = true
	_sim_paused = false
	_map_id = PlayableDemoConfig.map_id()
	_session = GameSession.new()
	_boot_map(_map_id)
	GameTestHelpers.new_settlement(_session, PlayableDemoConfig.settlement_point())
	PlayableDemoConfig.apply_starting_resources(_session.settlement)
	_spawn_demo_clay_deposit()
	_objective_tracker = DemoObjectiveTracker.new(_session)
	_objective_tracker.reset_for_new_game()
	if not _objective_tracker.objective_completed.is_connected(_on_objective_completed):
		_objective_tracker.objective_completed.connect(_on_objective_completed)
	if not _objective_tracker.step_advanced.is_connected(_on_objective_step_advanced):
		_objective_tracker.step_advanced.connect(_on_objective_step_advanced)
	_wire_gameplay()
	_enable_playable_demo_ui()
	_refresh_demo_world_hints()
	_hide_start_menu()
	_camera_ctrl.fit_island()
	var status := "Settlement demo — lumber delivery, then brickyard chain"
	if PlayableDemoConfig.snapshot_key() == "playable_northern_expedition":
		status = "Northern expedition — follow objectives and map markers"
	_hud.show_status(status)
	if _success_panel != null:
		_success_panel.hide_success()


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
	if not MessageBus.building_selected.is_connected(_on_bus_building_selected):
		MessageBus.building_selected.connect(_on_bus_building_selected)
	if not MessageBus.settlement_updated.is_connected(_refresh_all_building_views):
		MessageBus.settlement_updated.connect(_refresh_all_building_views)
	if not MessageBus.collector_motion_changed.is_connected(_refresh_all_building_views):
		MessageBus.collector_motion_changed.connect(_refresh_all_building_views)
	if not MessageBus.inventory_changed.is_connected(_refresh_all_building_views):
		MessageBus.inventory_changed.connect(_refresh_all_building_views)
	_ensure_collector_layer()
	_hud.ensure_logbook_panel()
	_hud.refresh()
	_update_ghost()
	for child in _building_layer.get_children():
		child.queue_free()
	_views.clear()
	for b in _session.get_buildings_on_island(_session.island):
		_attach_view(b)


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
	if not _screenshot_out.is_empty():
		_screenshot_frames += 1
		if _screenshot_frames >= SCREENSHOT_WARMUP_FRAMES:
			_write_screenshot_and_quit()
		return
	if not _game_active or _session == null:
		return
	if not _sim_paused:
		_sim_clock.accumulate_and_run(_session, delta, func():
			MessageBus.settlement_updated.emit()
		)
	if _playable_demo and _objective_tracker != null:
		_objective_tracker.tick_after_sim()
	if not _video_slice.is_empty():
		_video_time += delta
		_run_video_timeline()
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


func _refresh_all_building_views(_unused: Variant = null) -> void:
	for view in _views.values():
		if view is BuildingView:
			(view as BuildingView).refresh_from_sim()


func _ensure_collector_layer() -> void:
	if _collector_layer != null or _session == null:
		return
	_collector_layer = CollectorViewLayer.new()
	_collector_layer.name = "CollectorViewLayer"
	add_child(_collector_layer)
	_collector_layer.setup(_session, _map_view)


func _attach_view(building: Building) -> void:
	var view := BuildingView.new()
	_building_layer.add_child(view)
	view.bind(building, _map_view)
	_views[building.worldid] = view
	if building.worldid == _selected_worldid:
		view.set_highlighted(true)


func _on_bus_building_selected(building: Building) -> void:
	if building == null:
		return
	_selected_worldid = building.worldid
	for wid in _views.keys():
		var view: BuildingView = _views[wid] as BuildingView
		if view != null:
			view.set_highlighted(int(wid) == _selected_worldid)


func toggle_sim_pause() -> void:
	_sim_paused = not _sim_paused
	var panel := _hud.get_objective_panel()
	if panel != null:
		panel.set_paused(_sim_paused)
	_hud.show_status("Simulation paused" if _sim_paused else "Simulation running")


func _enable_playable_demo_ui() -> void:
	_hud.set_playable_demo_active(_playable_demo)
	if _playable_demo:
		_hud.set_snapshot_extra_fields(_merge_demo_into_snapshot)
	else:
		_hud.set_snapshot_extra_fields(Callable())
	if _playable_demo and _objective_tracker != null:
		_hud.bind_objective_tracker(_objective_tracker)
		var panel := _hud.get_objective_panel()
		if panel != null and not panel.pause_toggled.is_connected(toggle_sim_pause):
			panel.pause_toggled.connect(toggle_sim_pause)
		_ensure_success_overlay()


func _refresh_demo_world_hints() -> void:
	if not _playable_demo or _objective_tracker == null:
		if _demo_world_hints != null:
			_demo_world_hints.visible = false
		return
	if _demo_world_hints == null:
		_demo_world_hints = DemoWorldHints.new()
		_demo_world_hints.name = "DemoWorldHints"
		add_child(_demo_world_hints)
		_demo_world_hints.setup(_map_view)
	_demo_world_hints.visible = true
	_demo_world_hints.bind_tracker(_objective_tracker)


func _ensure_success_overlay() -> void:
	if _success_layer != null:
		return
	_success_layer = CanvasLayer.new()
	_success_layer.layer = 12
	add_child(_success_layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_success_layer.add_child(center)
	_success_panel = DemoSuccessPanel.new()
	center.add_child(_success_panel)
	_success_panel.continue_playing.connect(_on_success_continue)
	_success_panel.restart_demo.connect(_on_success_restart)
	_success_panel.return_to_menu.connect(_on_success_menu)


func _spawn_demo_clay_deposit() -> void:
	var cfg := PlayableDemoConfig.clay_deposit_cfg()
	if not bool(cfg.get("spawn_at_start", false)):
		return
	var at := PlayableDemoConfig.clay_deposit_point()
	var deposit: Building = BuildCommand.new(
		GameConstants.BUILDINGS["CLAY_DEPOSIT"],
		at.x,
		at.y,
		_session.island,
		null,
		true
	).execute(_session) as Building
	if deposit == null:
		push_warning("Demo clay deposit could not be placed at %s" % at)
		return
	if cfg.has("seed_raw_clay"):
		deposit.get_storage().alter(
			GameConstants.RES["RAW_CLAY"], int(cfg["seed_raw_clay"])
		)


func _on_objective_step_advanced(step_index: int) -> void:
	if step_index == 1:
		_hud.show_status("Clay deposit marked on the island — build pit, then brickyard")
		_refresh_demo_world_hints()
		if _demo_world_hints != null:
			_camera_ctrl.focus_world_point(_demo_world_hints.clay_marker_center())
	else:
		_hud.show_status("Objective updated")
	GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")


func _on_objective_completed() -> void:
	_ensure_success_overlay()
	_success_panel.show_success()
	GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")
	_hud.show_status("Objective complete — materials delivered!")


func _on_success_continue() -> void:
	if _success_panel != null:
		_success_panel.hide_success()


func _on_success_restart() -> void:
	if _success_panel != null:
		_success_panel.hide_success()
	_start_playable_settlement_demo()


func _on_success_menu() -> void:
	if _success_panel != null:
		_success_panel.hide_success()
	_teardown_session_to_menu()


func _teardown_session_to_menu() -> void:
	_playable_demo = false
	_sim_paused = false
	_objective_tracker = null
	if _demo_world_hints != null:
		_demo_world_hints.queue_free()
		_demo_world_hints = null
	_session = null
	_build_tool = null
	_hud.set_playable_demo_active(false)
	for child in _building_layer.get_children():
		child.queue_free()
	_views.clear()
	_show_start_menu()


func _merge_demo_into_snapshot(snap: Dictionary) -> Dictionary:
	if _playable_demo and _objective_tracker != null:
		snap["demo"] = _objective_tracker.to_snapshot_demo_block()
	return snap


func _apply_demo_from_snapshot(data: Dictionary) -> void:
	if not data.has("demo"):
		return
	var demo: Variant = data["demo"]
	if typeof(demo) != TYPE_DICTIONARY:
		return
	PlayableDemoConfig.set_profile_from_snapshot(demo)
	_playable_demo = true
	if _objective_tracker == null:
		_objective_tracker = DemoObjectiveTracker.new(_session)
	_objective_tracker.bind_session(_session)
	_objective_tracker.apply_snapshot_demo_block(demo)
	if not _objective_tracker.objective_completed.is_connected(_on_objective_completed):
		_objective_tracker.objective_completed.connect(_on_objective_completed)
	if not _objective_tracker.step_advanced.is_connected(_on_objective_step_advanced):
		_objective_tracker.step_advanced.connect(_on_objective_step_advanced)
	_enable_playable_demo_ui()
	_refresh_demo_world_hints()
	if _objective_tracker.completed:
		_ensure_success_overlay()
		_success_panel.show_success()


func _on_save_requested() -> void:
	if _session == null:
		return
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	var snap := _merge_demo_into_snapshot(_session.to_snapshot())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_hud.show_status("Save failed: could not write user://", true)
		return
	file.store_string(JSON.stringify(snap, "\t"))
	file.close()
	_start_menu.refresh_continue_availability()
	if OS.has_feature("web"):
		_hud.show_status("Saved JSON — use Download in HUD to keep a copy")
	else:
		_hud.show_status("Saved JSON to user://poc_snapshot.json — Continue on menu works now")


func _on_load_requested() -> void:
	var path := SaveLoadPanel.DEFAULT_SAVE_PATH
	if not FileAccess.file_exists(path):
		if OS.has_feature("web"):
			_hud.show_status("No save yet — use Load JSON or finish a step and Save", true)
		else:
			_hud.show_status("No save at user://poc_snapshot.json — Save JSON first", true)
		return
	var text := FileAccess.get_file_as_string(path)
	_load_snapshot_text(text)


func _on_import_snapshot(json_text: String) -> void:
	if _load_snapshot_text(json_text):
		_hide_start_menu()
		_camera_ctrl.fit_island()


func _on_import_save_file(path: String) -> void:
	if SqliteSaveLoader.is_extract_bundle_file(path):
		_on_import_sqlite(path)
		return
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
	if OS.has_feature("web") and not SqliteSaveLoader.is_extract_bundle_file(path):
		_hud.show_status("Raw .sqlite is desktop-only; use JSON or .extract.json", true)
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
	_hud.show_status(report.summarize_for_hud())
	print("SqliteImportReport: ", JSON.stringify(report.to_dictionary()))


func _on_showcase_requested() -> void:
	_playable_demo = false
	_objective_tracker = null
	_hud.set_playable_demo_active(false)
	if _success_panel != null:
		_success_panel.hide_success()
	var scenario_path := DemoConfig.showcase_scenario_path()
	var scenario := DemoScenarioRunner.load_dict(scenario_path)
	if scenario.is_empty():
		_hud.show_status("Showcase scenario missing", true)
		return
	_map_id = str(scenario.get("map_id", DemoConfig.default_map_id()))
	var warmup := float(scenario.get("sim_warmup_seconds", 45.0))
	_session = DemoScenarioRunner.boot_from_dict(scenario, warmup)
	if _session == null:
		_hud.show_status("Showcase failed to start", true)
		return
	if _build_tool == null:
		_wire_gameplay()
	else:
		_apply_session(_session)
	_hide_start_menu()
	_camera_ctrl.fit_island()
	_hud.show_status("Living village showcase — sim running, explore freely")


func _load_snapshot_text(json_text: String) -> bool:
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		_hud.show_status("Invalid save JSON", true)
		return false
	if _session == null:
		_session = GameSession.new()
		_boot_map(_map_id)
		_wire_gameplay()
	_playable_demo = false
	_objective_tracker = null
	if _success_panel != null:
		_success_panel.hide_success()
	var before := _session.get_buildings_on_island(_session.island).size()
	var result := _session.try_load_snapshot(data)
	if not result["ok"]:
		_hud.show_status("Load failed: %s" % str(result.get("error", "")), true)
		if _session.get_buildings_on_island(_session.island).size() != before:
			push_error("Session mutated after failed load")
		return false
	_apply_session(_session)
	_apply_demo_from_snapshot(data)
	if not _playable_demo:
		_hud.set_playable_demo_active(false)
	var status := "JSON save loaded"
	if _playable_demo and _objective_tracker != null:
		status += " (%s)" % _objective_tracker.step_label_short()
	_hud.show_status(status)
	return true


func _boot_map(map_id: String) -> void:
	_map_id = map_id
	MapLoader.apply_map_to_session(_session, map_id)


func _on_map_selected(map_id: String) -> void:
	if _playable_demo:
		return
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
	_game_active = true
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
	var valid := _build_tool.can_place_at(_hover_grid)
	var tint := Color(0.35, 1.0, 0.35, 0.65) if valid else Color(1.0, 0.25, 0.25, 0.65)
	var frames := BuildingVisualRegistry.get_sprite_frames_for_building(_build_tool.building_id)
	if frames != null and frames.get_animation_names().size() > 0:
		var anim: StringName = frames.get_animation_names()[0]
		if frames.get_frame_count(anim) > 0:
			_ghost.texture = frames.get_frame_texture(anim, 0)
			var stem := ContentLoader.stem_for_building_id(_build_tool.building_id)
			tint *= BuildingVisualRegistry.get_dlc_tint(stem)
			tint.a = 0.65 if valid else 0.55
	_ghost.modulate = tint
	var ctx := &"build"
	if _context_manager != null:
		ctx = _context_manager.get_context_name()
	_ghost.visible = ctx != &"select" and _build_tool.active


func _parse_capture_cmdline() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot-out="):
			_screenshot_out = arg.trim_prefix("--screenshot-out=")
		elif arg.begins_with("--screenshot-preset="):
			_screenshot_preset = arg.trim_prefix("--screenshot-preset=").strip_edges()
		elif arg.begins_with("--video-slice="):
			_video_slice = arg.trim_prefix("--video-slice=").strip_edges()
		elif arg.begins_with("--video-duration="):
			_video_duration = float(arg.trim_prefix("--video-duration="))


func _bootstrap_video_slice() -> void:
	match _video_slice:
		"settlement_demo":
			_start_playable_settlement_demo()
			_seed_screenshot_boards_step()
			_compose_screenshot_frame()
			_video_time = 0.0
			_video_flags.clear()
			_hud.show_status("Settlement demo — lumber, then clay deposit for brickyard")
		"living_village":
			_bootstrap_living_village_video()
		_:
			push_error("Unknown video slice: %s" % _video_slice)
			get_tree().quit(1)


func _bootstrap_living_village_video() -> void:
	_playable_demo = false
	_objective_tracker = null
	_game_active = true
	_video_duration = 34.0
	var scenario_path := DemoConfig.showcase_scenario_path()
	var scenario := DemoScenarioRunner.load_dict(scenario_path)
	if scenario.is_empty():
		push_error("Showcase scenario missing for living_village video")
		get_tree().quit(1)
		return
	_map_id = str(scenario.get("map_id", DemoConfig.default_map_id()))
	_session = DemoScenarioRunner.boot_from_dict(scenario, 24.0)
	if _session == null:
		get_tree().quit(1)
		return
	_wire_gameplay()
	_hide_start_menu()
	_compose_screenshot_frame()
	_video_time = 0.0
	_video_flags = {"scenario": scenario, "spots": ["wide", "lumber", "food", "brickyard", "dlc", "hud"], "spot_i": -1}
	_hud.show_status("Northern Company living settlement")
	$CanvasLayer.visible = false


func _run_video_timeline() -> void:
	if _video_time >= _video_duration:
		get_tree().quit()
		return
	if _video_slice == "living_village":
		_run_living_village_video_timeline()
		return
	if _video_time >= 2.0 and not bool(_video_flags.get("focus_camp")):
		_video_flags["focus_camp"] = true
		_camera_ctrl.focus_world_point(_map_view.grid_to_screen(Vector2i(32, 32)), 1.4, 1.22)
	if _video_time >= 9.0 and not bool(_video_flags.get("step2")):
		_video_flags["step2"] = true
		var boards_res := int(GameConstants.RES["BOARDS"])
		var need := 8
		var have := _session.settlement.inventory.amount(boards_res)
		if have < need:
			_session.settlement.inventory.alter(boards_res, need - have)
		if _objective_tracker != null:
			_objective_tracker.current_step_index = 1
			_objective_tracker.state_changed.emit()
		_refresh_demo_world_hints()
		_hud.show_status("Clay deposit marked — build pit, then brickyard")
		_on_objective_step_advanced(1)
	if _video_time >= 10.0 and not bool(_video_flags.get("focus_clay")):
		_video_flags["focus_clay"] = true
		if _demo_world_hints != null:
			_camera_ctrl.focus_world_point(_demo_world_hints.clay_marker_center(), 1.6, 1.32)
	if _video_time >= 19.0 and not bool(_video_flags.get("success")):
		_video_flags["success"] = true
		_seed_screenshot_success_state()
		_hud.show_status("Objective complete — materials delivered!")
	if _video_time >= 23.0 and not bool(_video_flags.get("fit_end")):
		_video_flags["fit_end"] = true
		_camera_ctrl.focus_world_point(_map_view.grid_to_screen(Vector2i(30, 30)), 1.2, 1.05)


func _run_living_village_video_timeline() -> void:
	var scenario: Dictionary = _video_flags.get("scenario", {})
	var spots: Array = _video_flags.get("spots", [])
	var spot_i := int(_video_flags.get("spot_i", -1))
	var interval := 5.5
	var next_i := int(floor(_video_time / interval))
	if next_i >= spots.size():
		next_i = spots.size() - 1
	if next_i <= spot_i:
		return
	_video_flags["spot_i"] = next_i
	var spot_id := str(spots[next_i])
	var spot := DemoScenarioRunner.camera_spot(scenario, spot_id)
	var grid := Vector2i(int(spot.get("x", 30)), int(spot.get("y", 30)))
	var zoom := float(spot.get("zoom", 1.15))
	_camera_ctrl.focus_world_point(_map_view.grid_to_screen(grid), zoom, 1.1)
	if spot_id == "hud":
		$CanvasLayer.visible = true
	else:
		$CanvasLayer.visible = false


func _bootstrap_screenshot_preset() -> void:
	if _screenshot_preset.begins_with("showcase_"):
		_bootstrap_showcase_screenshot(_screenshot_preset.trim_prefix("showcase_"))
		return
	match _screenshot_preset:
		"title":
			_show_start_menu()
			$CanvasLayer.visible = false
		"boards":
			PlayableDemoConfig.use_short_demo()
			_start_playable_settlement_demo()
			_seed_screenshot_boards_step()
			_compose_screenshot_frame()
		"clay_hint":
			PlayableDemoConfig.use_short_demo()
			_start_playable_settlement_demo()
			_seed_screenshot_clay_hint_step()
			_compose_screenshot_frame()
		"success":
			PlayableDemoConfig.use_short_demo()
			_start_playable_settlement_demo()
			_seed_screenshot_success_state()
			_compose_screenshot_frame()
		_:
			push_error("Unknown screenshot preset: %s" % _screenshot_preset)
			get_tree().quit(1)


func _bootstrap_showcase_screenshot(spot_id: String) -> void:
	_playable_demo = false
	_objective_tracker = null
	_game_active = true
	var scenario_path := DemoConfig.showcase_scenario_path()
	var scenario := DemoScenarioRunner.load_dict(scenario_path)
	if scenario.is_empty():
		push_error("Showcase scenario missing for screenshot")
		get_tree().quit(1)
		return
	_map_id = str(scenario.get("map_id", DemoConfig.default_map_id()))
	var warmup := float(scenario.get("sim_warmup_seconds", 90.0))
	_session = DemoScenarioRunner.boot_from_dict(scenario, warmup)
	if _session == null:
		get_tree().quit(1)
		return
	_wire_gameplay()
	_hide_start_menu()
	_compose_screenshot_frame()
	var spot := DemoScenarioRunner.camera_spot(scenario, spot_id)
	var grid := Vector2i(int(spot.get("x", 30)), int(spot.get("y", 30)))
	var zoom := float(spot.get("zoom", 1.15))
	_camera_ctrl.focus_world_point(_map_view.grid_to_screen(grid), zoom, 0.01)
	if spot_id == "hud":
		$CanvasLayer.visible = true
		_hud.show_status("Northern Company living settlement")
	else:
		$CanvasLayer.visible = false


func _seed_screenshot_boards_step() -> void:
	var island := _session.island
	var settlement := _session.settlement
	BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 32, 32, island, settlement
	).execute(_session)
	for tree_xy in [Vector2i(32, 30), Vector2i(34, 30)]:
		BuildCommand.new(
			GameConstants.BUILDINGS["TREE"], tree_xy.x, tree_xy.y, island, settlement
		).execute(_session)
	var boards_res := int(GameConstants.RES["BOARDS"])
	var have_boards := settlement.inventory.amount(boards_res)
	settlement.inventory.alter(boards_res, 5 - have_boards)
	_sync_building_views()
	_objective_tracker.state_changed.emit()
	_hud.refresh()
	_camera_ctrl.fit_island()


func _seed_screenshot_clay_hint_step() -> void:
	var island := _session.island
	var settlement := _session.settlement
	BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 32, 32, island, settlement
	).execute(_session)
	for tree_xy in [Vector2i(32, 30), Vector2i(34, 30)]:
		BuildCommand.new(
			GameConstants.BUILDINGS["TREE"], tree_xy.x, tree_xy.y, island, settlement
		).execute(_session)
	if _objective_tracker != null:
		_objective_tracker.current_step_index = 1
		_objective_tracker.state_changed.emit()
	_refresh_demo_world_hints()
	_sync_building_views()
	_objective_tracker.state_changed.emit()
	_hud.refresh()
	if _demo_world_hints != null:
		_camera_ctrl.focus_world_point(_demo_world_hints.clay_marker_center(), 0.01, 1.35)
	else:
		_camera_ctrl.fit_island()


func _seed_screenshot_success_state() -> void:
	if _objective_tracker != null:
		_objective_tracker.current_step_index = 2
		_objective_tracker.completed = true
		_objective_tracker.state_changed.emit()
	_ensure_success_overlay()
	_success_panel.show_success()
	_camera_ctrl.fit_island()


func _compose_screenshot_frame() -> void:
	_map_view.set_polygon_ground_only(true)
	if _context_manager != null:
		_context_manager.set_context(&"select")
	if _hud != null:
		_hud.prepare_for_screenshot()
	_update_ghost()


func _sync_building_views() -> void:
	if _session == null:
		return
	for b in _session.get_buildings_on_island(_session.island):
		if not _views.has(b.worldid):
			_attach_view(b)
	if _hud != null:
		_hud.refresh()


func _write_screenshot_and_quit() -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Screenshot: empty framebuffer")
		get_tree().quit(1)
		return
	var err := img.save_png(_screenshot_out)
	if err != OK:
		push_error("Screenshot: save_png failed (%s)" % error_string(err))
		get_tree().quit(1)
		return
	print("PocMain: wrote screenshot %s (preset=%s)" % [_screenshot_out, _screenshot_preset])
	get_tree().quit()
