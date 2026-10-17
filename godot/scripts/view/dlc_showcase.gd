extends Node2D

@onready var _map_view: MapView = $MapView
@onready var _layer: Node2D = $BuildingLayer
@onready var _label: Label = $CanvasLayer/Label

var _session: GameSession


func _ready() -> void:
	_session = GameSession.new()
	_session.load_test_map()
	GameTestHelpers.new_settlement(_session, TestMapFactory.default_settlement_point())
	_map_view.bind(_session.island)
	_spawn_demo_buildings()
	_label.text = "DLC showcase — base lumberjack (left) vs Northern Smokery (right, tinted)"


func _spawn_demo_buildings() -> void:
	var base_lj: Building = BuildCommand.new(
		GameConstants.BUILDINGS["LUMBERJACK"], 28, 32, _session.island, _session.settlement
	).execute(_session) as Building
	var dlc_smokery: Building = BuildCommand.new(
		DlcConstants.BUILDINGS["NORTHERN_SMOKERY"], 34, 32, _session.island, _session.settlement
	).execute(_session) as Building
	for b in [base_lj, dlc_smokery]:
		if b == null:
			continue
		var view := BuildingView.new()
		_layer.add_child(view)
		view.bind(b, _map_view)
		if b.get_producer() != null:
			b.get_storage().alter(GameConstants.RES["FISH"], 2)
	_session.run_seconds(5)
	for child in _layer.get_children():
		if child is BuildingView:
			(child as BuildingView).refresh_from_sim()
