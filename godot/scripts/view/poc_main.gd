extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _hud: GameHud = $CanvasLayer/HUD
@onready var _building_sprite: Sprite2D = $BuildingSprite
@onready var _ghost: Sprite2D = $GhostSprite

var _session: GameSession
var _build_tool: BuildTool
var _buildings: Array[Building] = []
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


func _process(delta: float) -> void:
	_tick_accum += delta
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	while _tick_accum >= step:
		_session.run_ticks(1)
		_tick_accum -= step
		MessageBus.settlement_updated.emit()
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
	_buildings.append(building)
	_building_sprite.position = _map_view.grid_to_screen(building.position)


func _update_ghost() -> void:
	_ghost.position = _map_view.grid_to_screen(_hover_grid)
	if _build_tool.can_place_at(_hover_grid):
		_ghost.modulate = Color(0.3, 0.9, 0.3, 0.55)
	else:
		_ghost.modulate = Color(0.9, 0.2, 0.2, 0.55)
	_ghost.visible = _build_tool.active
