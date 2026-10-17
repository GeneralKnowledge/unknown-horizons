class_name MapCameraController
extends Node

## Pan/zoom for MapView + Camera2D (middle drag, wheel zoom).

@export var min_zoom: float = 0.35
@export var max_zoom: float = 2.5
@export var zoom_step: float = 0.1

var _camera: Camera2D
var _map_view: MapView
var _dragging := false
var _last_mouse := Vector2.ZERO
var _ui_blocker: Callable = Callable()


func setup(p_camera: Camera2D, p_map_view: MapView) -> void:
	_camera = p_camera
	_map_view = p_map_view


func set_ui_blocker(blocker: Callable) -> void:
	_ui_blocker = blocker


func fit_island() -> void:
	if _camera == null or _map_view == null or _map_view.island == null:
		return
	var bounds := MapGroundBounds.compute_screen_aabb(_map_view)
	if bounds.size == Vector2.ZERO:
		return
	_camera.position = bounds.get_center()
	var view_size := get_viewport().get_visible_rect().size
	var zx := view_size.x / maxf(bounds.size.x, 1.0)
	var zy := view_size.y / maxf(bounds.size.y, 1.0)
	var z := clampf(minf(zx, zy) * 0.85, min_zoom, max_zoom)
	_camera.zoom = Vector2(z, z)


func focus_world_point(
	world_pos: Vector2,
	duration: float = 0.85,
	zoom_in_factor: float = 1.18
) -> void:
	if _camera == null:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_camera, "position", world_pos, duration).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)
	var z := clampf(_camera.zoom.x * zoom_in_factor, min_zoom, max_zoom)
	tween.tween_property(_camera, "zoom", Vector2(z, z), duration).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		return
	if _is_over_ui():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(1.0 + zoom_step)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(1.0 / (1.0 + zoom_step))
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_last_mouse = mb.position
	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _last_mouse
		_last_mouse = mm.position
		_camera.position -= delta / _camera.zoom
		get_viewport().set_input_as_handled()


func _apply_zoom(factor: float) -> void:
	var z := clampf(_camera.zoom.x * factor, min_zoom, max_zoom)
	_camera.zoom = Vector2(z, z)


func _is_over_ui() -> bool:
	if _ui_blocker.is_valid():
		return bool(_ui_blocker.call())
	return false
