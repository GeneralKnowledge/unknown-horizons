# Legacy SQLite import (frozen experiment)

**Policy (Godot-first):** Godot [**JSON snapshot v3**](SAVE_FORMAT.md) is the shipping save format (desktop `user://`, browser download/upload). Legacy **`.sqlite`** import is an **experimental desktop path** for occasional manual testing—not a product requirement and **not** a gate for new gameplay work.

## What import does today

- **Desktop:** PoC **Import legacy SQLite** (start menu / HUD) runs `SqliteSaveLoader` + Python extract scripts under `development/godot/`.
- **Web:** Raw `.sqlite` is unsupported; use prebuilt **`.extract.json`** bundles when you need legacy-derived state in WASM ([`sqlite_extract_bundle.py`](../../development/godot/sqlite_extract_bundle.py)).
- **Diagnostics:** Imports set `partial: true` when ships, paths, settlers upgrades/goods, or other subsystems are missing or stubbed. The HUD uses [`SqliteImportReport.summarize_for_hud()`](../../scripts/sim/save/sqlite_import_report.gd).

## What we will not expand (unless policy changes)

- Parity with the Python/FIFE client on the same save file
- Settler upgrade chains, ships/paths fidelity, full savegamerev-76 T1b depth, reverse export to `.sqlite`
- Cross-version multiplayer or “play Python + Godot together”
- New features that **require** passing more sqlite tiers or T1m dual-run

Historical tracker (status frozen): [`M7_LEGACY_SAVE.md`](M7_LEGACY_SAVE.md).

## Allowed changes to import code

- **Crash fixes** or breakage from extract script / schema drift on existing fixtures
- **Regression tests** that keep current behavior documented (no new parity scope)

Do **not** extend `SqliteSaveLoader` or extract scripts for new gameplay systems—implement those on JSON v3 + sim rules instead.

## Tests and CI

- Default CI still runs sqlite smoke/matrix and Godot tick-128 goldens (**T1l**) as **regression guards**.
- **T1m** (Godot vs legacy Python after ticks) runs only when **`RUN_T1M=1`** and FIFE is installed locally—see `godot/tests/integration/test_sqlite_m7_legacy_dual_run.gd`.
- Optional future grouping: GUT tests under `test_sqlite_*.gd` may be tagged `legacy_import` for selective runs (`-gselect=legacy_import` when configured); not required for day-to-day PRs.

## Related docs

- [`MIGRATION_STRATEGY.md`](MIGRATION_STRATEGY.md) — Godot-first cutover criteria
- [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) — **M8** Godot-native play backlog
- [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) — fixture tags (T0–T1p)
