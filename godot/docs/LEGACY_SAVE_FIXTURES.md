# Legacy save fixtures (SQLite)

Godot loads legacy Unknown Horizons saves **partially** today (buildings + storage rows on desktop). Use committed fixtures to catch crashes and track gaps.

## In-repo fixtures (CI)

| File | Path |
|------|------|
| `savegame-rev-76.sqlite` | `legacy/tests/game/fixtures/` |
| `blackdeath`, `fire`, `traderoute`, `settlement-range` | `legacy/tests/game/fixtures/` |
| `large.sqlite.bz2` | `legacy/tests/game/fixtures/` (decompressed in matrix) |
| `boatbuilder`, `plain`, `ai_settlement`, … | `legacy/tests/gui/ingame/fixtures/` |

There is **no official public save library** from the UH project. Players share `.sqlite` files manually ([FAQ](https://github.com/unknown-horizons/unknown-horizons/wiki/FAQ)). To add community saves, open a PR placing files under `development/godot/fixtures/saves/community/` with provenance (game version, author, license) in [`development/godot/fixtures/saves/README.md`](../../development/godot/fixtures/saves/README.md).

## Run the matrix locally

```bash
python3 development/godot/export_content.py
python3 development/godot/sqlite_fixture_matrix.py
```

Report: [`development/godot/reports/sqlite_fixture_report.json`](../../development/godot/reports/sqlite_fixture_report.json)

Godot desktop list for GUT: [`godot/resources/fixtures/sqlite_save_fixtures.json`](../resources/fixtures/sqlite_save_fixtures.json)

## Tiers

| Tier | Meaning |
|------|---------|
| **T0** | SQLite valid, extract script OK, `SqliteSaveLoader.load` returns a session (GUT) |
| **T1** | Gap report: unknown `building.type` ids, storage/unit row counts |
| **T2** | Full legacy Python load (needs `fife`) — optional, not in default CI |

## Current Godot loader scope

[`SqliteSaveLoader`](../scripts/sim/save/sqlite_save_loader.gd):

- Rev **76→77** bump via [`sqlite_upgrade_save.py`](../../development/godot/sqlite_upgrade_save.py) (no FIFE) inside [`sqlite_prepare_save.py`](../../development/godot/sqlite_prepare_save.py)
- Session header (tick estimate, `next_worldid`) via [`sqlite_extract_session.py`](../../development/godot/sqlite_extract_session.py)
- Buildings via [`sqlite_extract_buildings.py`](../../development/godot/sqlite_extract_buildings.py) (limit `0` = all rows)
- Storage via [`sqlite_extract_storage.py`](../../development/godot/sqlite_extract_storage.py)
- Wild animals via [`sqlite_extract_units.py`](../../development/godot/sqlite_extract_units.py) (`kind: wild_animal`)
- Ground from save `metadata.map_name` when a bundled [`export_maps.py`](../../development/godot/export_maps.py) map exists (`development`, `test_map_tiny`, `quattro`); otherwise test stub
- `.sqlite.bz2` saves decompressed via [`sqlite_prepare_save.py`](../../development/godot/sqlite_prepare_save.py) (desktop)
- No `SavegameUpgrader` — rev **76** fixture tests upgrade path in **legacy** pytest only

Web builds: JSON snapshots only ([`SAVE_FORMAT.md`](SAVE_FORMAT.md)).

## Reading the gap report

- **`unknown_building_type_ids`** — missing export / `GameConstants` mapping
- **`storage_rows` / `unit_rows`** — future loader work ordering
- **`savegamerev`** — compare to `legacy/horizons/constants.py` `SAVEGAMEREVISION`
