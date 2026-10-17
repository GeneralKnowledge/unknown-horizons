class_name MapView
extends Node2D

const TILE_W := 32
const TILE_H := 16

var island: Island
var map_origin := Vector2(320, 180)
var _land_color := Color(0.22, 0.48, 0.22)
var _coast_color := Color(0.18, 0.38, 0.62)
var _water_color := Color(0.12, 0.28, 0.55)
var _ground_layer: TileMapLayer
var _ground_tileset: TileSet


func _ready() -> void:
	_load_gfx_index_colors()
	_ground_layer = TileMapLayer.new()
	_ground_layer.name = "GroundTileMap"
	add_child(_ground_layer)
	_build_ground_tileset()


func bind(p_island: Island) -> void:
	island = p_island
	_refresh_ground_tilemap()
	queue_redraw()


func grid_to_screen(grid: Vector2i) -> Vector2:
	return map_origin + Vector2(
		(grid.x - grid.y) * (TILE_W / 2.0),
		(grid.x + grid.y) * (TILE_H / 2.0)
	)


func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - map_origin
	var gx := int(round(local.x / float(TILE_W) + local.y / float(TILE_H)))
	var gy := int(round(local.y / float(TILE_H) - local.x / float(TILE_W)))
	return Vector2i(gx, gy)


func _draw() -> void:
	if island == null:
		return
	for coords in island.ground_map.keys():
		var kind: int = int(island.ground_map[coords])
		var color := _water_color
		if kind == SimGround.Kind.LAND:
			color = _land_color
		elif kind == SimGround.Kind.SHALLOW_WATER:
			color = _coast_color
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		var center := grid_to_screen(c)
		var half_w := Vector2(TILE_W / 2.0, TILE_H / 2.0)
		var diamond := PackedVector2Array([
			center + Vector2(0, -half_w.y),
			center + Vector2(half_w.x, 0),
			center + Vector2(0, half_w.y),
			center + Vector2(-half_w.x, 0),
		])
		draw_colored_polygon(diamond, color)


func _load_gfx_index_colors() -> void:
	const INDEX_PATH := "res://resources/gfx/index.json"
	if not FileAccess.file_exists(INDEX_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	var ground: Dictionary = data.get("ground", {})
	if ground.has("land_rgba"):
		var rgba: Array = ground["land_rgba"]
		_land_color = Color(rgba[0] / 255.0, rgba[1] / 255.0, rgba[2] / 255.0, rgba[3] / 255.0)
	if ground.has("coast_rgba"):
		var rgba2: Array = ground["coast_rgba"]
		_coast_color = Color(rgba2[0] / 255.0, rgba2[1] / 255.0, rgba2[2] / 255.0, rgba2[3] / 255.0)
	if ground.has("water_rgba"):
		var rgba3: Array = ground["water_rgba"]
		_water_color = Color(rgba3[0] / 255.0, rgba3[1] / 255.0, rgba3[2] / 255.0, rgba3[3] / 255.0)
	_build_ground_tileset()


func _build_ground_tileset() -> void:
	if _ground_layer == null:
		return
	_ground_tileset = TileSet.new()
	var atlas := TileSetAtlasSource.new()
	var img := Image.create(96, 16, false, Image.FORMAT_RGBA8)
	for i in range(3):
		var col: Color = [_water_color, _coast_color, _land_color][i]
		for x in range(32):
			for y in range(16):
				img.set_pixel(i * 32 + x, y, col)
	var tex := ImageTexture.create_from_image(img)
	atlas.texture = tex
	atlas.create_tile(Vector2i(0, 0))
	atlas.create_tile(Vector2i(1, 0))
	atlas.create_tile(Vector2i(2, 0))
	_ground_tileset.add_source(atlas, 0)
	_ground_layer.tile_set = _ground_tileset


func _refresh_ground_tilemap() -> void:
	if _ground_layer == null or island == null:
		return
	_ground_layer.clear()
	for coords in island.ground_map.keys():
		var kind: int = int(island.ground_map[coords])
		var tile_index := 0
		if kind == SimGround.Kind.LAND:
			tile_index = 2
		elif kind == SimGround.Kind.SHALLOW_WATER:
			tile_index = 1
		var c: Vector2i = coords if coords is Vector2i else Vector2i(coords[0], coords[1])
		_ground_layer.set_cell(c, 0, Vector2i(tile_index, 0))
