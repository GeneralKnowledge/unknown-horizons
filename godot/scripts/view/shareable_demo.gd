extends Node2D

## Visual-only demo island for marketing screenshots (headless capture + manual runs).

const FRAMES_BEFORE_CAPTURE := 10
const SCREENSHOT_SCENARIO := "res://resources/demo/shareable_screenshot_scenario.json"

@onready var _map_view: MapView = $MapView
@onready var _building_layer: Node2D = $BuildingLayer
@onready var _camera: Camera2D = $Camera2D
@onready var _title_bar: PanelContainer = $CanvasLayer/TitleBar
@onready var _title: Label = $CanvasLayer/TitleBar/VBox/Title
@onready var _subtitle: Label = $CanvasLayer/TitleBar/VBox/Subtitle

var _session: GameSession
var _frames := 0
var _screenshot_path := ""


func _ready() -> void:
	_parse_cmdline()
	DemoConfig.apply_theme_pack_if_configured()
	_apply_title_theme()
	_title.text = DemoConfig.title()
	_subtitle.text = DemoConfig.subtitle()
	if _subtitle.text.is_empty():
		_subtitle.text = "Godot port — settlement sim in the browser"

	var scenario_path := DemoConfig.showcase_scenario_path()
	if not _screenshot_path.is_empty() and FileAccess.file_exists(SCREENSHOT_SCENARIO):
		scenario_path = SCREENSHOT_SCENARIO
	var warmup := 3.0 if not _screenshot_path.is_empty() else 25.0
	_session = DemoScenarioRunner.boot_from_resource(scenario_path, warmup)
	if _session == null:
		push_error("ShareableDemo: failed to boot scenario")
		return
	_map_view.set_polygon_ground_only(true)
	_map_view.bind(_session.island)
	for b in _session.get_buildings_on_island(_session.island):
		var view := BuildingView.new()
		_building_layer.add_child(view)
		view.bind(b, _map_view)
	_fit_camera()


func _parse_cmdline() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot-out="):
			_screenshot_path = arg.trim_prefix("--screenshot-out=")


func _apply_title_theme() -> void:
	var pack_theme := ContentTheme.get_ui_theme()
	if pack_theme != null:
		_title_bar.theme = pack_theme
	var accent := ContentTheme.hud_accent_color()
	_title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	_subtitle.add_theme_color_override("font_color", accent)


func _fit_camera() -> void:
	var bounds := _building_screen_bounds()
	if bounds.size == Vector2.ZERO:
		bounds = MapGroundBounds.compute_screen_aabb(_map_view)
	if bounds.size == Vector2.ZERO:
		return
	_camera.position = bounds.get_center()
	var view_size := get_viewport().get_visible_rect().size
	var zx := view_size.x / maxf(bounds.size.x, 1.0)
	var zy := view_size.y / maxf(bounds.size.y, 1.0)
	var z := clampf(minf(zx, zy) * 0.75, 0.35, 2.5)
	_camera.zoom = Vector2(z, z)


func _building_screen_bounds() -> Rect2:
	if _session == null or _map_view == null:
		return Rect2()
	var bounds := Rect2()
	var island := _session.island
	for b in _session.get_buildings_on_island(island):
		var p := _map_view.grid_to_screen(b.position)
		if bounds.size == Vector2.ZERO:
			bounds = Rect2(p, Vector2.ZERO)
		else:
			bounds = bounds.expand(p)
	if bounds.size == Vector2.ZERO:
		return bounds
	return bounds.grow(96.0)


func _process(_delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames < FRAMES_BEFORE_CAPTURE:
		return
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		push_error("ShareableDemo: empty framebuffer")
		get_tree().quit(1)
		return
	var err := img.save_png(_screenshot_path)
	if err != OK:
		push_error("ShareableDemo: save_png failed (%s)" % error_string(err))
		get_tree().quit(1)
		return
	print("ShareableDemo: wrote %s" % _screenshot_path)
	get_tree().quit()
