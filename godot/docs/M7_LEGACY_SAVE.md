# M7 — Cross-version saves & play (progress)

M7 is the **gate** before treating Godot as the primary Unknown Horizons client ([`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md#future-ideas)). This doc tracks progress against **six exit criteria** only—not a second roadmap.

**Progress reporting:** use exit criteria **#1–#4** (percent / status). Labels like T1b, T1n in [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) are **GUT test tags**, not milestone tiers.

## Exit criteria (checklist)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Fixture saves load in Godot without silent loss | **Partial** | SQLite fixture matrix GUT; `SqliteImportReport` + `partial` flag |
| 2 | Python → Godot → play (campaign slice) | **Partial** | Desktop `.sqlite` / `.extract.json`; PoC sim after load; no full GUI campaign |
| 3 | Parity on loaded state | **Strong partial** | T1b/T1k on main fixtures; T1n production on `fire`, `settlement-range`, `traderoute`; T1p session tick; T1o matrix gate |
| 4 | Parity after N ticks vs golden | **Partial** | **T1l** Godot tick-128 goldens (`fire`, `settlement-range`); **T1m** legacy Python dual-run when FIFE installed (optional; pending in CI) |
| 5 | Cross-version session (stretch) | **Not scheduled** | Do not plan until exit **#4** is green on multiple fixtures |
| 6 | Reverse save path (stretch) | **Not scheduled** | JSON v3 only for Godot-native saves today |

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
| Production | Restore lines / progress | T1n on fire, settlement-range, traderoute |
| Collectors | Spawn + in-flight jobs | **Done** ([`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md)) |
| Settlers | Residential restore + partial sim | Tier limits, happiness storage, legacy tax + inhabitant checks; no upgrades / goods |
| Units | Wild animals; ships placeholder | Partial |
| Session / multi-island | PoC single settlement | Partial |

## Automated tests (tags)

See [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) for T0–T1p tag → test mapping. Run:

```bash
./godot/run_tests.sh
python3 development/godot/sqlite_fixture_matrix.py
python3 development/godot/sqlite_storage_expectations.py
```

Regenerate Godot tick-128 golden (`fire`):

```bash
cd godot && WRITE_M7_GOLDEN=1 godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gconfig=.gutconfig.json -gunit_test_name=tick128_inventory -gexit
```

Optional local legacy Python dual-run (requires FIFE + legacy deps; not in default CI):

```bash
python3 development/godot/sqlite_m7_legacy_fire_ticks.py \
  legacy/tests/game/fixtures/fire.sqlite /tmp/legacy_fire_128.json --ticks 128
```

## Open work (exit #3 and #4 only)

1. **Exit #3 — large / rev-76 storage:** choose **either** per-building T1b on `savegame-rev-76` **or** keep totals-only T1k; do not expand both in parallel.
2. **Exit #4 — tick parity:** extend T1l to another fixture when stable; run T1m locally with FIFE and fix Godot vs legacy drift on `fire` when found.
3. **Settler goods / upgrades:** only if tick goldens regress after monthly settler sim; not a separate roadmap phase.

Stretch exit criteria **#5–#6** stay out of the backlog until **#4** is satisfied on multiple fixtures.
