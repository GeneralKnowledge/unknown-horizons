extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _hud: GameHud = $CanvasLayer/HUD
@onready var _building_layer: Node2D = $BuildingLayer
@onready var _ghost: Sprite2D = $GhostSprite

var _session: GameSession
var _build_tool: BuildTool
var _views: Dictionary = {} # worldid -> BuildingView
var _sim_clock := SimClock.new()
var _hover_grid := Vector2i.ZERO


func _ready() -> void:
	_session = GameSession.new()
	_session.load_test_map()
	GameTestHelpers.new_settlement(_session, TestMapFactory.default_settlement_point())
	_build_tool = BuildTool.new(_session)
	_build_tool.building_placed.connect(_on_building_placed)
	_map_view.bind(_session.island)
	_hud.bind(_session, _build_tool)
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
	if event is InputEventMouseButton and event.pressed:
		var grid := _map_view.screen_to_grid(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			var placed := _build_tool.try_place(grid)
			if placed != null:
				_hud.set_selected(placed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var picked := _pick_building_at(grid)
			if picked != null:
				MessageBus.building_selected.emit(picked)
				_hud.set_selected(picked)
	if event.is_action_pressed("ui_select"):
		_build_tool.active = not _build_tool.active
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_build_tool.set_palette_lumberjack()
			KEY_2:
				_build_tool.set_palette_tree()
			KEY_3:
				_build_tool.set_palette_tear()
			KEY_T:
				_build_tool.set_palette_tear()


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


func _pick_building_at(grid: Vector2i) -> Building:
	for b in _session.get_buildings_on_island(_session.island):
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(b.building_id)
		)
		for tile in BuildFootprint.origin_tiles(
			b.position, int(export.get("size_x", 1)), int(export.get("size_y", 1))
		):
			if tile == grid:
				return b
	return null


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


func _apply_session(new_session: GameSession) -> void:
	_session = new_session
	_sim_clock.reset()
	_build_tool = BuildTool.new(_session)
	_build_tool.building_placed.connect(_on_building_placed)
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
	_ghost.visible = _build_tool.active
