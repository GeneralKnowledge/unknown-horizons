# M7 — Cross-version saves & play (progress)

M7 is the **gate** before treating Godot as the primary Unknown Horizons client ([`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md#future-ideas)). This doc tracks **measurable** progress toward the exit criteria—not a second roadmap.

## Exit criteria (checklist)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Fixture saves load in Godot without silent loss | **Partial** | SQLite fixture matrix GUT; `SqliteImportReport` + `partial` flag |
| 2 | Python → Godot → play (campaign slice) | **Partial** | Desktop `.sqlite` / `.extract.json`; PoC sim after load; no full GUI campaign |
| 3 | Parity on loaded state | **In progress** | T1b all building storages on `fire`; T1k settlement + per-resource totals at load |
| 4 | Parity after N ticks vs golden | **Started** | T1d tick smoke; no Python dual-run on full save yet |
| 5 | Cross-version session (stretch) | **Not started** | — |
| 6 | Reverse save path (stretch) | **Not started** | JSON v3 only for Godot-native saves |

## Player workflow (today)

**Desktop — continue a Python save in Godot (experimental)**

1. In legacy Unknown Horizons, save the game (`.sqlite` in the user save folder).
2. Copy the file into a path Godot can read (any folder; use **Import legacy SQLite** on the start menu or HUD).
3. Prefer **JSON** for the bundled demo loop; use **SQLite** when testing legacy import.
4. Read the import report in logs / HUD diagnostics: `partial: true` means ships, paths, or unsupported units still differ from Python.

**Web**

- Raw `.sqlite` is not supported in the browser.
- Use a prebuilt **`.extract.json`** bundle ([`sqlite_extract_bundle.py`](../../development/godot/sqlite_extract_bundle.py), e.g. [`fire.extract.json`](../resources/fixtures/sqlite_bundles/fire.extract.json)).

## Partial-import subsystems

| Subsystem | Partial-import scope | Status |
|-----------|----------------------|--------|
| Buildings + placement | Trust legacy coordinates | Done for fixtures |
| Storage | Building + settlement rows | **Done on `fire`** (T1b/T1k) |
| Production | Restore lines / progress | Subset + GUT |
| Collectors | Spawn + in-flight jobs | **Done** ([`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md)) |
| Settlers | Residential meta | Meta only |
| Units | Wild animals; ships placeholder | Partial |
| Session / multi-island | PoC single settlement | Partial |

## Automated tiers

See [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) (T0–T1k). Run:

```bash
./godot/run_tests.sh
python3 development/godot/sqlite_fixture_matrix.py
python3 development/godot/sqlite_storage_expectations.py
```

## Suggested order toward full M7

1. **Storage** — extend T1b/T1k to `traderoute`, `savegame-rev-76`, … (fixture list in `sqlite_save_fixtures.json`).
2. **Post-load tick inventory** — dual-run or golden totals after fixed tick count on `fire`.
3. **Settler minimal sim** — inhabitants affect gameplay, not only meta.
4. **Documented unsupported fields** — shrink `partial` causes on reference saves.
5. **Cross-version session** — only after (1)–(3) are green on multiple fixtures.
