class_name DemoWorldHints
extends Node2D

## Playable-demo overlays: pulsing marker where the player should build next.

var _map_view: MapView
var _tracker: DemoObjectiveTracker
var _pulse := 0.0


func setup(p_map_view: MapView) -> void:
	_map_view = p_map_view
	z_as_relative = false


func bind_tracker(tracker: DemoObjectiveTracker) -> void:
	if _tracker != null and _tracker.state_changed.is_connected(_on_tracker_state_changed):
		_tracker.state_changed.disconnect(_on_tracker_state_changed)
	_tracker = tracker
	if _tracker != null:
		if not _tracker.state_changed.is_connected(_on_tracker_state_changed):
			_tracker.state_changed.connect(_on_tracker_state_changed)
	_pulse = 0.0
	queue_redraw()


func _on_tracker_state_changed() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if not _should_show_clay_marker():
		return
	_pulse += delta
	queue_redraw()


func clay_marker_center() -> Vector2:
	if _map_view == null:
		return Vector2.ZERO
	var at := PlayableDemoConfig.clay_deposit_point()
	return _map_view.grid_to_screen(at)


func _should_show_clay_marker() -> bool:
	if _tracker == null or _map_view == null:
		return false
	if _tracker.completed:
		return false
	var step := _tracker.current_step()
	if str(step.get("id", "")) != "bricks":
		return false
	return _tracker.clay_pit_count() < 1


func _draw() -> void:
	if not _should_show_clay_marker():
		return
	var center := clay_marker_center()
	var pulse := 0.5 + 0.5 * sin(_pulse * 3.2)
	var outer := 22.0 + pulse * 6.0
	var inner := 14.0 + pulse * 3.0
	var clay := Color(0.72, 0.42, 0.28, 0.92)
	var ring := Color(1.0, 0.88, 0.55, 0.35 + pulse * 0.25)
	_draw_iso_diamond(center, outer, ring, 3.0)
	_draw_iso_diamond(center, inner, clay, 2.0)
	draw_circle(center + Vector2(0, -28), 4.0, ring)
	draw_line(center + Vector2(0, -24), center + Vector2(0, -14), ring, 2.0)
	var font := ThemeDB.fallback_font
	var label := "Clay deposit"
	var fs := 13
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(
		font,
		center + Vector2(-tw.x * 0.5, -34),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		Color(1, 0.96, 0.82, 0.95)
	)


func _draw_iso_diamond(center: Vector2, radius: float, color: Color, width: float) -> void:
	var hw := radius * 1.35
	var hh := radius * 0.65
	var pts := PackedVector2Array([
		center + Vector2(0, -hh),
		center + Vector2(hw, 0),
		center + Vector2(0, hh),
		center + Vector2(-hw, 0),
		center + Vector2(0, -hh),
	])
	draw_polyline(pts, color, width)
