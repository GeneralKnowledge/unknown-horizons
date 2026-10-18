# M7 — Legacy import experiment (frozen)

**Intent:** This milestone tracked **cross-version save & play** as a cutover gate. Under the **Godot-first** pivot, M7 is **frozen**: PoC desktop import met its purpose; there are **no further exit criteria** and **no expansion** for gameplay parity with Python/FIFE.

**Read first:** [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md) — policy, allowed changes, CI notes.

**Progress reporting (historical):** exit criteria **#1–#4** below describe what the fixture matrix proved. Labels like T1b, T1n in [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) are **GUT test tags**, not active roadmap tiers.

## Exit criteria (historical checklist)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Fixture saves load in Godot without silent loss | **Partial (accepted)** | SQLite fixture matrix GUT; `SqliteImportReport` + `partial` flag |
| 2 | Python → Godot → play (campaign slice) | **Partial (experimental)** | Desktop `.sqlite` / `.extract.json`; PoC sim after load; no full GUI campaign |
| 3 | Parity on loaded state | **Strong partial** | T1b/T1k on main fixtures; T1n on fire, settlement-range, traderoute; T1p session tick; T1o matrix gate |
| 4 | Parity after N ticks vs golden | **Godot side met (T1l)** | tick-128 on fire, settlement-range, traderoute, blackdeath, plain; **T1m** optional local/FIFE only |
| 5 | Cross-version session (stretch) | **Out of scope** | Not planned under Godot-first |
| 6 | Reverse save path (stretch) | **Not scheduled** | JSON v3 for Godot-native saves |

## Player workflow (today)

**Desktop — continue a Python save in Godot (experimental)**

1. In legacy Unknown Horizons, save the game (`.sqlite` in the user save folder).
2. Copy the file into a path Godot can read (any folder; use **Import legacy SQLite** on the start menu or HUD).
3. Prefer **JSON** for the bundled demo loop; use **SQLite** only when testing legacy import.
4. Read the import report in logs / HUD diagnostics: `partial: true` means ships, paths, or unsupported units still differ from Python.

**Web**

- Raw `.sqlite` is not supported in the browser.
- Use a prebuilt **`.extract.json`** bundle ([`sqlite_extract_bundle.py`](../../development/godot/sqlite_extract_bundle.py), e.g. [`fire.extract.json`](../resources/fixtures/sqlite_bundles/fire.extract.json)).

## Partial-import subsystems

| Subsystem | Partial-import scope | Status |
|-----------|----------------------|--------|
| Buildings + placement | Trust legacy coordinates | Done for fixtures |
| Storage | Building + settlement rows | Done on main trio; rev-76 totals (T1k) |
| Production | Restore lines / progress | T1n on fire, settlement-range, traderoute |
| Collectors | Spawn + in-flight jobs | Done ([`COLLECTOR_SQLITE_IMPORT.md`](COLLECTOR_SQLITE_IMPORT.md)) |
| Settlers | Residential restore + partial sim | Tier limits, happiness storage, legacy tax + inhabitant checks — **will not** extend to upgrades / goods chains for sqlite |
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

Optional local legacy Python dual-run (**T1m**, requires **`RUN_T1M=1`** + FIFE; not default CI):

```bash
RUN_T1M=1 ./godot/run_tests.sh
# or: ./development/godot/run_t1m_fire.sh /tmp/legacy_fire_128.json
```

Legacy stack with FIFE: see [`legacy/README.md`](../../legacy/README.md) or [`legacy/development/docker/Dockerfile`](../../legacy/development/docker/Dockerfile).

## M7 PoC gate status (2026-10) — closed

**CI-complete for the in-repo fixture matrix:** load (T0–T1k/T1n/T1p), storage parity policy, collectors, settler partial sim, and Godot tick-128 goldens (T1l) on tier fixtures except **`savegame-rev-76`** (totals-only at load by policy). `report.partial` remains expected for ships, paths, and unsupported units.

This gate is **closed for product planning**. Further sqlite work is **maintenance-only** per [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md).

## Will not fix (explicit)

1. **T1m** as a merge blocker — optional FIFE dual-run only.
2. **`savegame-rev-76` full T1b/T1l** — keep T1k totals-only unless unrelated sim work forces a revisit.
3. **Settler upgrades / goods / deep T1n** on legacy saves — implement in Godot-native JSON gameplay instead.
