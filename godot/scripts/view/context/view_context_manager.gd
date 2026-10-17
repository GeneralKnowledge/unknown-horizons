class_name ViewContextManager
extends Node

signal context_changed(context_name: StringName)

var session: GameSession
var build_tool: BuildTool
var map_view: MapView

var _select := SelectViewContext.new()
var _build := BuildViewContext.new()
var _tear := TearViewContext.new()
var _current: BaseViewContext
var _current_name: StringName = &"build"


func setup(p_session: GameSession, p_build_tool: BuildTool, p_map_view: MapView) -> void:
	session = p_session
	build_tool = p_build_tool
	map_view = p_map_view
	set_context(&"build")


func set_context(name: StringName) -> void:
	if _current != null:
		_current.exit(self)
	_current_name = name
	match name:
		&"select":
			_current = _select
			build_tool.active = false
		&"tear":
			_current = _tear
		_:
			_current_name = &"build"
			_current = _build
	_current.enter(self)
	context_changed.emit(_current_name)


func get_context_name() -> StringName:
	return _current_name


func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	return map_view.screen_to_grid(screen_pos)


func pick_building_at(grid: Vector2i) -> Building:
	for b in session.get_buildings_on_island(session.island):
		var export := ContentLoader.load_building_export(
			ContentLoader.stem_for_building_id(b.building_id)
		)
		for tile in BuildFootprint.origin_tiles(
			b.position, int(export.get("size_x", 1)), int(export.get("size_y", 1))
		):
			if tile == grid:
				return b
	return null


func process_input(event: InputEvent) -> void:
	if _current == null:
		return
	_current.handle_input(event, self)
