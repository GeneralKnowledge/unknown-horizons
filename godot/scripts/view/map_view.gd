class_name MapView
extends Node2D

const TILE_W := 32
const TILE_H := 16

var island: Island
var map_origin := Vector2(320, 180)


func bind(p_island: Island) -> void:
	island = p_island
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
		var color := Color(0.12, 0.28, 0.55)
		if kind == SimGround.Kind.LAND:
			color = Color(0.22, 0.48, 0.22)
		elif kind == SimGround.Kind.SHALLOW_WATER:
			color = Color(0.18, 0.38, 0.62)
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
