# Legacy SQLite — collector rows (design)

## How Godot spawns collectors today

1. `BuildingFactory.create_building()` attaches components from exported YAML.
2. `CollectingComponent` reads collector **unit type ids + counts** from the building export and calls `CollectorRegistry.create_collector()` immediately.
3. Collectors are **not** world-positioned units; they are sim objects tied to the home building.

## What legacy saves store

| Table | Relevant columns |
|-------|------------------|
| `unit` | `rowid`, `type`, `x`, `y`, `owner` |
| `building_collector` | `rowid` (= unit worldid), `home_building`, `creation_tick` |

Saved collectors have map positions and scheduler history Godot does not model yet.

## Current import behaviour (this repo)

- **Wild animals** (`wildanimal` + `unit` type `WILD_ANIMAL`): restored with saved `worldid` and tile position.
- **Collectors**: counted in `SqliteImportReport` only:
  - `collectors_skipped_yaml_duplicate` — save row matches a home building that already has YAML-spawned collectors (no duplicate spawn).
  - `collectors_unsupported` — ships, settlers, or collectors without a collecting building.

Imports remain **`partial: true`** when collector rows exist in the save.

## Safe follow-up (not implemented here)

1. **Unit world nodes** (or sim records) with position for non-wild units.
2. **Restore collector count mismatch** — only when YAML spec count &lt; save row count *and* explicit opt-in (still no path/job replay).
3. **Do not** replay `unit_path`, `collector_job`, or `building_collector_job_history` until scheduler parity exists.

## Prerequisites for full collector fidelity

- Production / scheduler tick restore (`production.remaining_ticks`, etc.) — **partial:** [`sqlite_extract_production.py`](../../development/godot/sqlite_extract_production.py) + `Production.restore_from_legacy_save` on desktop SQLite import
- Collector job state machine parity with legacy `BuildingCollector`
- Settlement ownership and multi-island `location` column handling
