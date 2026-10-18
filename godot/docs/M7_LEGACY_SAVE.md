# M7 — Cross-version saves & play (progress)

M7 is the **gate** before treating Godot as the primary Unknown Horizons client ([`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md#future-ideas)). This doc tracks progress against **six exit criteria** only—not a second roadmap.

**Progress reporting:** use exit criteria **#1–#4** (percent / status). Labels like T1b, T1n in [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) are **GUT test tags**, not milestone tiers.

## Exit criteria (checklist)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Fixture saves load in Godot without silent loss | **Partial** | SQLite fixture matrix GUT; `SqliteImportReport` + `partial` flag |
| 2 | Python → Godot → play (campaign slice) | **Partial** | Desktop `.sqlite` / `.extract.json`; PoC sim after load; no full GUI campaign |
| 3 | Parity on loaded state | **Strong partial** | T1b/T1k on main fixtures; T1n production on `fire`, `settlement-range`, `traderoute`; T1p session tick; T1o matrix gate |
| 4 | Parity after N ticks vs golden | **Strong partial (Godot)** | **T1l** tick-128 on `fire`, `settlement-range`, `traderoute`, `blackdeath`, `plain`; cross-engine **T1m** needs FIFE locally (pending in CI) |
| 5 | Cross-version session (stretch) | **Out of scope (M7 PoC)** | Requires server/sync design — see [`MIGRATION_STRATEGY.md`](MIGRATION_STRATEGY.md) |
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

## M7 PoC gate status (2026-10)

**CI-complete for the in-repo fixture matrix:** load (T0–T1k/T1n/T1p), storage parity policy, collectors, settler partial sim, and Godot tick-128 goldens (T1l) on all tier fixtures except **`savegame-rev-76`** (totals-only at load by policy). `report.partial` remains expected for ships, paths, and unsupported units — exit **#1** is satisfied when imports are explicit, not when every legacy subsystem is ported.

| Exit | PoC gate |
|------|----------|
| **#1** | Met for matrix fixtures (partial flag documented) |
| **#2** | Met for experimental desktop import + sim; not full campaign GUI |
| **#3** | Met for full-parity trio + totals-only policy on rev-76/plain/blackdeath |
| **#4** | Met on Godot side (T1l); **T1m** is the remaining cross-engine check |
| **#5–#6** | Not part of this gate |

**Overall (~75% of full M7 vision):** single-player legacy continue on committed fixtures is test-gated; stretch multiplayer/reverse-save is explicitly deferred.

## Remaining (optional, not blocking PoC gate)

1. **T1m:** run `sqlite_m7_legacy_fire_ticks.py` on a machine with **FIFE**; fix inventory drift vs Godot if any.
2. **`savegame-rev-76`:** keep **T1k totals-only** unless promoting to full T1b/T1l with a dedicated perf budget.
3. **Settler upgrades / goods:** only if T1l goldens fail after sim changes.
