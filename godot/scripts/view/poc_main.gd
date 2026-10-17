extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _hud: GameHud = $CanvasLayer/HUD
@onready var _building_layer: Node2D = $BuildingLayer
@onready var _ghost: Sprite2D = $GhostSprite

var _session: GameSession
var _build_tool: BuildTool
var _views: Dictionary = {} # worldid -> BuildingView
var _tick_accum := 0.0
var _hover_grid := Vector2i.ZERO


func _ready() -> void:
	_session = GameSession.new()
	_session.load_test_map()
	GameTestHelpers.new_settlement(_session, TestMapFactory.default_settlement_point())
	_build_tool = BuildTool.new(_session)
	_build_tool.building_placed.connect(_on_building_placed)
	_map_view.bind(_session.island)
	_hud.bind(_session)
	_hud.refresh()
	_update_ghost()
	if not MessageBus.building_placed.is_connected(_on_bus_building_placed):
		MessageBus.building_placed.connect(_on_bus_building_placed)


func _process(delta: float) -> void:
	_tick_accum += delta
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	while _tick_accum >= step:
		_session.run_ticks(1)
		_tick_accum -= step
		MessageBus.settlement_updated.emit()
		for view in _views.values():
			if view is BuildingView:
				(view as BuildingView).refresh_from_sim()
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_grid = _map_view.screen_to_grid(event.position)
		_update_ghost()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid := _map_view.screen_to_grid(event.position)
		var placed := _build_tool.try_place(grid)
		if placed != null:
			_hud.set_selected(placed)
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


func _update_ghost() -> void:
	_ghost.position = _map_view.grid_to_screen(_hover_grid)
	if _build_tool.can_place_at(_hover_grid):
		_ghost.modulate = Color(0.3, 0.9, 0.3, 0.55)
	else:
		_ghost.modulate = Color(0.9, 0.2, 0.2, 0.55)
	_ghost.visible = _build_tool.active
