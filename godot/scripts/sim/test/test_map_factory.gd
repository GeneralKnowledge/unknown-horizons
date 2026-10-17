class_name TestMapFactory
extends RefCounted

## Mirrors tests/game/utils.py create_map() — 20×20 island at world offset (20, 20).

const ISLAND_ORIGIN := Vector2i(20, 20)
const ISLAND_SIZE := 20


static func create_ground_map() -> Dictionary:
	var ground: Dictionary = {}
	for lx in range(ISLAND_SIZE):
		for ly in range(ISLAND_SIZE):
			var world := ISLAND_ORIGIN + Vector2i(lx, ly)
			var inner := lx > 0 and lx < ISLAND_SIZE - 1 and ly > 0 and ly < ISLAND_SIZE - 1
			ground[world] = SimGround.Kind.LAND if inner else SimGround.Kind.SHALLOW_WATER
	return ground


static func default_settlement_point() -> Vector2i:
	# Match tests/game/utils.py new_settlement(Point(30, 20)) — warehouse footprint must not
	# overlap common 3×3 build sites such as farm/barracks at (30, 30).
	return TestMapFactory.ISLAND_ORIGIN + Vector2i(10, 3)
