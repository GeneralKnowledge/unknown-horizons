# Demo scenario JSON (schema v1)

Single format for **living village showcase**, **playable expedition/short demo** configs, and (via shared fields) parity-style setup.

## Required / common fields

| Field | Type | Purpose |
|-------|------|---------|
| `schema_version` | `1` | Parser gate in [`demo_scenario_document.gd`](../scripts/view/demo/demo_scenario_document.gd) |
| `kind` | `"showcase"` \| `"playable"` | Showcase boots buildings; playable supplies `steps` for [`DemoObjectiveTracker`](../scripts/view/demo/demo_objective_tracker.gd) |
| `id` or `demo_id` | string | Snapshot key for playable (`playable_lumber`, `playable_northern_expedition`) |

Some tier-1/ DLC buildings (e.g. pavilion, signal tower) may not place on every map tile until E3 buildability parity lands; prefer coordinates validated by GUT on the target `map_id`.
| `map_id` | string | e.g. `development`, `test_island_20x20` |
| `settlement` | `{x,y}` | Warehouse / settlement origin |

## Showcase boot

| Field | Purpose |
|-------|---------|
| `sim_warmup_seconds` | Run sim after placement ([`DemoScenarioDocument.boot_session`](../scripts/view/demo/demo_scenario_document.gd)) |
| `chain` | Legacy shorthand (lumberjack, hunter, fisher, clay, brickyard) |
| `placements` / `ownerless_placements` / `dlc_placements` | Explicit `{building,x,y}` lists |
| `starting_inventory` | Settlement stock before warmup |
| `seed_building_storage` | `{building, resource, amount}` on first matching building |
| `camera_spots` | Screenshot / video presets (`wide`, `lumber`, …) |

## Playable objectives

| Field | Purpose |
|-------|---------|
| `steps` | Objective milestones (resource targets, `require_buildings`, hints) |
| `world_hints` | Map marker positions keyed by step id |
| `clay_deposit` | Spawn ownerless deposit at start (PoC helper) |
| `success_message` | Success overlay copy |

## Parity relationship

Parity files under [`development/godot/parity/scenarios/`](../../development/godot/parity/scenarios/) use **`steps[]` with `op`** (`build`, `run_seconds`, …) consumed by [`ScenarioRunner`](../scripts/parity/scenario_runner.gd). Demo v1 does **not** replace parity ops; reuse the same **map** and **settlement** naming where possible (`map` vs `map_id` both accepted in documents).

## Examples

- Showcase: [`resources/demo/northern_village_showcase.json`](../resources/demo/northern_village_showcase.json)
- Short playable: [`resources/demo/playable_lumber_demo.json`](../resources/demo/playable_lumber_demo.json)
- Expedition: [`resources/demo/playable_northern_expedition.json`](../resources/demo/playable_northern_expedition.json)
