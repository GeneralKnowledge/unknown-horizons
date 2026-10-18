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
| **T1b** | After load, placed building **storage** matches `sqlite_extract_storage.py` for **≥10** buildings on `fire.sqlite` (GUT: `test_sqlite_storage_parity.gd`; goldens: `resources/fixtures/sqlite_storage/*.json` via `sqlite_storage_expectations.py`) |
| **T1c** | Collectors restored from save without YAML double-spawn (GUT: `test_sqlite_collector_restore.gd`); settlement `storage` → `settlement.inventory` |
| **T1d** | Post-load tick stepping: load → N ticks → economy moves without crash (GUT: `test_sqlite_tick_parity.gd`) |
| **T1e** | Ships / misc units → `LegacyUnit` placeholders at saved positions (GUT: `test_sqlite_legacy_units.gd`) |
| **T1f** | Prebuilt `.extract.json` bundles for web import (GUT: `test_sqlite_extract_bundle.gd`; tool: `sqlite_extract_bundle.py`) |
| **T1g** | Python probe ↔ Godot import counts (GUT: `test_sqlite_cross_version_probe.gd`) |
| **T1h** | Residential settler rows → building meta (`legacy_inhabitants`, `legacy_last_tax_payed`; GUT: `test_sqlite_settler_restore.gd`) |
| **T1i** | Active `collector_job` in-transit cargo on collectors at load (GUT: `test_sqlite_collector_jobs.gd`, `test_sqlite_import_diagnostics.gd`) |
| **T2** | Full legacy Python load (needs `fife`) — optional, not in default CI |

## Current Godot loader scope

[`SqliteSaveLoader`](../scripts/sim/save/sqlite_save_loader.gd):

- Rev **76→77** bump via [`sqlite_upgrade_save.py`](../../development/godot/sqlite_upgrade_save.py) (no FIFE) inside [`sqlite_prepare_save.py`](../../development/godot/sqlite_prepare_save.py)
- Session header (tick estimate, `next_worldid`) via [`sqlite_extract_session.py`](../../development/godot/sqlite_extract_session.py)
- **Settlement / island worldids** from [`sqlite_extract_settlement.py`](../../development/godot/sqlite_extract_settlement.py): PoC single-settlement loads re-key `session.settlement` and `session.island` to legacy `rowid` / `island` (multi-settlement saves: first player-owned row when island id does not match yet)
- Buildings via [`sqlite_extract_buildings.py`](../../development/godot/sqlite_extract_buildings.py) (limit `0` = all rows), placed with **`trust_legacy_placement`** (saved coordinates win over live buildability rules)
- Storage via [`sqlite_extract_storage.py`](../../development/godot/sqlite_extract_storage.py) (building `object` worldids + **settlement** rowids via [`sqlite_extract_settlement.py`](../../development/godot/sqlite_extract_settlement.py))
- Production state via [`sqlite_extract_production.py`](../../development/godot/sqlite_extract_production.py) — after storage, before collectors
- Collectors via [`sqlite_extract_units.py`](../../development/godot/sqlite_extract_units.py) (`kind: collector`) — see [`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md)
- Settler/residential meta via [`sqlite_extract_settler.py`](../../development/godot/sqlite_extract_settler.py) (`settler_building` rows)
- In-flight collector jobs via [`sqlite_extract_collector_jobs.py`](../../development/godot/sqlite_extract_collector_jobs.py) (`active_jobs` in bundles)
- Wild animals via same extract (`kind: wild_animal`)
- Ground from save `metadata.map_name` when a bundled [`export_maps.py`](../../development/godot/export_maps.py) map exists (`development`, `test_map_tiny`, `quattro`); otherwise test stub
- `.sqlite.bz2` saves decompressed via [`sqlite_prepare_save.py`](../../development/godot/sqlite_prepare_save.py) (desktop)
- No `SavegameUpgrader` — rev **76** fixture tests upgrade path in **legacy** pytest only

Web builds: JSON snapshots, or legacy **`.extract.json`** bundles ([`sqlite_extract_bundle.py`](../../development/godot/sqlite_extract_bundle.py) → e.g. [`resources/fixtures/sqlite_bundles/fire.extract.json`](../resources/fixtures/sqlite_bundles/fire.extract.json)). Raw `.sqlite` still requires desktop Python extracts.

## Import diagnostics

`SqliteSaveLoader.load_with_report(path)` returns `{ ok, session, report }`. After `load()`, read `SqliteSaveLoader.get_report(session)` for:

- `buildings_extracted` / `buildings_placed` / `buildings_rejected` + `rejection_counts` (`placement_failed`, `unknown_building_type`, …)
- `buildings_truncated` when Python extract hit a limit (marker row from `--include-skipped`)
- Storage, production, collector, and **`unsupported_unit_rows`** counts; **`rejection_counts.placement_failed`** (expect **0** on `fire.sqlite` with trust placement)

**Partial imports** set `report.partial = true` — not a full legacy save. See [`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md).

## Reading the gap report

- **`unknown_building_type_ids`** — missing export / `GameConstants` mapping
- **`storage_rows` / `unit_rows`** — future loader work ordering
- **`savegamerev`** — compare to `legacy/horizons/constants.py` `SAVEGAMEREVISION`
