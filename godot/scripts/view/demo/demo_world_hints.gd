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
	if _active_marker().is_empty():
		return
	_pulse += delta
	queue_redraw()


func clay_marker_center() -> Vector2:
	return marker_center_for_step("clay_deposit")


func marker_center_for_step(step_key: String) -> Vector2:
	if _map_view == null:
		return Vector2.ZERO
	var at := PlayableDemoConfig.hint_point_for_step(step_key)
	if at == Vector2i.ZERO:
		at = PlayableDemoConfig.clay_deposit_point()
	return _map_view.grid_to_screen(at)


func _active_marker() -> Dictionary:
	if _tracker == null or _tracker.completed:
		return {}
	var step := _tracker.current_step()
	var step_id := str(step.get("id", ""))
	if step_id == "bricks" and _tracker.clay_pit_count() < 1:
		return _marker_cfg("clay_deposit", "Clay deposit")
	if step_id == "food" and _tracker.hunter_count() < 1 and _tracker.fisher_count() < 1:
		return _marker_cfg("food", "Hunter / fisher")
	if step_id == "tools" and _tracker.toolmaker_count() < 1:
		return _marker_cfg("tools", "Toolmaker")
	if step_id == "textile" and _tracker.weaver_count() < 1:
		return _marker_cfg("textile", "Weaver")
	if step_id == "dlc_smokery" and _tracker.dlc_count("NORTHERN_SMOKERY") < 1:
		return _marker_cfg("dlc_smokery", "Northern smokery")
	if step_id == "dlc_faith" and _tracker.dlc_count("NORTHERN_SIGNAL_TOWER") < 1:
		return _marker_cfg("dlc_tower", "Signal tower")
	return {}


func _marker_cfg(key: String, default_label: String) -> Dictionary:
	var hints := PlayableDemoConfig.world_hints()
	var node: Variant = hints.get(key, {})
	var label := default_label
	if typeof(node) == TYPE_DICTIONARY and node.has("label"):
		label = str(node.get("label"))
	return {"key": key, "label": label}


func _draw() -> void:
	var marker := _active_marker()
	if marker.is_empty() or _map_view == null:
		return
	var center := marker_center_for_step(str(marker.get("key", "clay_deposit")))
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
	var label := str(marker.get("label", "Build here"))
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
