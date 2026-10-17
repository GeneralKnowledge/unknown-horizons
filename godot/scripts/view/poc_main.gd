extends Node2D

@onready var _hud: Label = $CanvasLayer/HUD
@onready var _building_sprite: Sprite2D = $BuildingSprite

const TILE_W := 32
const TILE_H := 16
const MAP_ORIGIN := Vector2(320, 180)

var _session: GameSession
var _buildings: Array[Building] = []
var _tick_accum := 0.0
var _place_mode := true


func _ready() -> void:
	_session = GameSession.new()
	_session.load_test_map()
	var settled := GameTestHelpers.new_settlement(_session, TestMapFactory.default_settlement_point())
	_buildings.append(
		BuildCommand.new(
			GameConstants.BUILDINGS["LUMBERJACK"],
			30,
			30,
			_session.island,
			settled.settlement
		).execute(_session)
	)
	_sync_sprites()
	_update_hud()


func _process(delta: float) -> void:
	_tick_accum += delta
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	while _tick_accum >= step:
		_session.run_ticks(1)
		_tick_accum -= step
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid := _screen_to_grid(event.position)
		if _place_mode:
			var b := BuildCommand.new(
				GameConstants.BUILDINGS["LUMBERJACK"],
				grid.x,
				grid.y,
				_session.island,
				_session.settlement
			).execute(_session)
			if b != null:
				_buildings.append(b)
				_sync_sprites()
	if event.is_action_pressed("ui_accept"):
		if not _buildings.is_empty():
			_buildings[0].get_storage().alter(GameConstants.RES["TREES"], 2)
	if event.is_action_pressed("ui_select"):
		_place_mode = not _place_mode


func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - MAP_ORIGIN
	var gx := int(round(local.x / float(TILE_W) + local.y / float(TILE_H)))
	var gy := int(round(local.y / float(TILE_H) - local.x / float(TILE_W)))
	return Vector2i(gx, gy)


func _grid_to_screen(grid: Vector2i) -> Vector2:
	return MAP_ORIGIN + Vector2(
		(grid.x - grid.y) * (TILE_W / 2.0),
		(grid.x + grid.y) * (TILE_H / 2.0)
	)


func _sync_sprites() -> void:
	if _buildings.is_empty():
		return
	var latest := _buildings[_buildings.size() - 1]
	_building_sprite.position = _grid_to_screen(latest.position)


func _update_hud() -> void:
	if _buildings.is_empty():
		_hud.text = "Click to place lumberjack (buildability checked)"
		return
	var lj := _buildings[0]
	var inv := lj.get_storage()
	_hud.text = "Unknown Horizons Godot PoC\nClick: place lumberjack | Space: +2 trees | Select: toggle build mode\nTrees: %d  Boards: %d  State: %s  Buildings: %d" % [
		inv.amount(GameConstants.RES["TREES"]),
		inv.amount(GameConstants.RES["BOARDS"]),
		ProductionStates.name_for(lj.get_producer()._get_current_state()),
		_buildings.size(),
	]
