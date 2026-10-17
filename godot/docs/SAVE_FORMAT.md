# Save format (Godot port)

## JSON snapshot (authoritative)

Used by PoC save/load, GUT tests, and browser download/import.

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | int | Current: **3** (`GameSession.SNAPSHOT_VERSION`) |
| `next_worldid` | int | Next entity id allocator |
| `settlement_inventory` | dict | Resource id → amount (settlement warehouse) |
| `buildings` | array | Building records (see below) |

### Building record

| Field | Type | Description |
|-------|------|-------------|
| `worldid` | int | Stable instance id |
| `building_id` | int | `GameConstants.BUILDINGS` value |
| `x`, `y` | int | Origin tile |
| `storage` | dict | Resource id → amount |
| `producer_active` | bool | Optional; default true |

### Load order

Warehouses are replayed first so settlement attachment matches legacy ordering.

### Migration

`SaveMigration.migrate(data, from_version)` runs before `load_snapshot` applies state. Today v3→v3 is a no-op; future versions add steps there.

### Invalid saves

Missing `schema_version` or unknown version: loader should reject with a clear error (tests cover round-trip for v3).

## Legacy SQLite (desktop dev)

`.sqlite` UH savegames: subset building extraction via `development/godot/sqlite_extract_buildings.py` and `SqliteSaveLoader`. **Not available on web** (`OS.has_feature("web")`).

## What is not saved

Visual nodes, sprite state, camera, UI selection. Only sim snapshot fields above.

## Round-trip tests

- GUT: `test_session_save.gd`, `test_session_save_extended.gd`
- Parity: `development/godot/parity/scenarios/snapshot_roundtrip.json`
