# M7 — Cross-version saves & play (progress)

M7 is the **gate** before treating Godot as the primary Unknown Horizons client ([`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md#future-ideas)). This doc tracks **measurable** progress toward the exit criteria—not a second roadmap.

## Exit criteria (checklist)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Fixture saves load in Godot without silent loss | **Partial** | SQLite fixture matrix GUT; `SqliteImportReport` + `partial` flag |
| 2 | Python → Godot → play (campaign slice) | **Partial** | Desktop `.sqlite` / `.extract.json`; PoC sim after load; no full GUI campaign |
| 3 | Parity on loaded state | **Partial** | T1b/T1k on **`fire`**, **`settlement-range`**, **`traderoute`**; T1k totals-only on **`savegame-rev-76`** |
| 4 | Parity after N ticks vs golden | **Partial** | T1l `fire` tick-128 inventory golden; T1d tick smoke |
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
| Storage | Building + settlement rows | **Done** on `fire`, `settlement-range`, `traderoute`; rev-76 totals (T1k) |
| Production | Restore lines / progress | Subset + GUT |
| Collectors | Spawn + in-flight jobs | **Done** ([`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md)) |
| Settlers | Residential meta | Meta only |
| Units | Wild animals; ships placeholder | Partial |
| Session / multi-island | PoC single settlement | Partial |

## Automated tiers

See [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) (T0–T1l). Run:

```bash
./godot/run_tests.sh
python3 development/godot/sqlite_fixture_matrix.py
python3 development/godot/sqlite_storage_expectations.py
```

Regenerate tick-128 golden (`fire`):

```bash
cd godot && WRITE_M7_GOLDEN=1 godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gconfig=.gutconfig.json -gunit_test_name=tick128_inventory -gexit
```

## Suggested order toward full M7

1. **Storage** — T1b per-building on `savegame-rev-76` (large) or accept totals-only; add `blackdeath` / `plain` when stable.
2. **Post-load tick inventory** — more fixtures + optional Python dual-run on `fire`.
3. **Settler minimal sim** — inhabitants affect gameplay, not only meta.
4. **Documented unsupported fields** — shrink `partial` causes on reference saves.
5. **Cross-version session** — only after (1)–(3) are green on multiple fixtures.
