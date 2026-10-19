class_name CollectorViewLayer
extends Node2D

## Draws simple haul markers for BuildingCollector path motion (view-only).

var _session: GameSession
var _map_view: MapView
var _markers: Array[Sprite2D] = []


func setup(p_session: GameSession, p_map_view: MapView) -> void:
	_session = p_session
	_map_view = p_map_view
	if not MessageBus.collector_motion_changed.is_connected(_refresh_markers):
		MessageBus.collector_motion_changed.connect(_refresh_markers)


func _process(_delta: float) -> void:
	_refresh_markers()


func _refresh_markers() -> void:
	if _session == null or _map_view == null:
		return
	var needed := 0
	for building in _session.get_buildings_on_island(_session.island):
		if building.collecting == null:
			continue
		for collector in building.collecting.collectors:
			if not collector is BuildingCollector:
				continue
			var bc := collector as BuildingCollector
			if bc.state != "moving" or bc.view_path.is_empty():
				continue
			needed += 1
			var marker := _marker_at(needed - 1)
			var grid := bc.get_view_grid_position()
			marker.position = _map_view.grid_to_screen(grid)
			marker.visible = true
	for i in range(needed, _markers.size()):
		_markers[i].visible = false


func _marker_at(index: int) -> Sprite2D:
	while _markers.size() <= index:
		var s := Sprite2D.new()
		s.texture = _dot_texture()
		s.scale = Vector2(0.35, 0.35)
		s.z_index = 500
		add_child(s)
		_markers.append(s)
	return _markers[index]


static var _cached_dot: Texture2D


static func _dot_texture() -> Texture2D:
	if _cached_dot != null:
		return _cached_dot
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(16):
		for y in range(16):
			if Vector2(x - 7.5, y - 7.5).length() < 6.0:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.2, 0.95))
	_cached_dot = ImageTexture.create_from_image(img)
	return _cached_dot
