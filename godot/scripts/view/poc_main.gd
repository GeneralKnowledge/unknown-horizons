extends Node2D

@onready var _hud: Label = $CanvasLayer/HUD
@onready var _building_sprite: Sprite2D = $BuildingSprite

var _session: GameSession
var _lumberjack: Building
var _tick_accum := 0.0


func _ready() -> void:
	_session = GameSession.new()
	_lumberjack = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"],
		30,
		30,
		_session.island,
		_session.settlement
	).execute(_session)
	_building_sprite.position = Vector2(30 * 32, 30 * 16)
	_update_hud()


func _process(delta: float) -> void:
	_tick_accum += delta
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	while _tick_accum >= step:
		_session.run_ticks(1)
		_tick_accum -= step
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_lumberjack.get_storage().alter(GameConstants.RES["TREES"], 2)
	if event.is_action_pressed("ui_select"):
		_lumberjack.get_storage().alter(GameConstants.RES["BOARDS"], -1)


func _update_hud() -> void:
	var inv := _lumberjack.get_storage()
	_hud.text = "Unknown Horizons Godot PoC\nSpace: add 2 trees | Enter: remove 1 board\nTrees: %d  Boards: %d  State: %s" % [
		inv.amount(GameConstants.RES["TREES"]),
		inv.amount(GameConstants.RES["BOARDS"]),
		ProductionStates.name_for(_lumberjack.get_producer()._get_current_state()),
	]
