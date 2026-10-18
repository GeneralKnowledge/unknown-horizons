# Unknown Horizons Godot Port — Project Roadmap

Last verified: **2026-10-18** — `./godot/run_tests.sh` **243** GUT pass; parity golden **12/12**; **Godot-first** — JSON v3 + demo are the product path; legacy SQLite import **frozen** — [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md); browser demo on `poc_main.tscn` (see [BROWSER_DEMO.md](BROWSER_DEMO.md)).

## Vision

Players eventually load the game from a URL (static hosting, no install). The **simulation** owns truth (settlements, inventories, production, commands, time). The **presentation** renders and sends commands; it must not invent resources or buildings.

Long-term the game may be rebranded (art, copy, buildings, factions, individuals). Stable **simulation identifiers** stay separate from display names and content packs.

## Core rule: UI → commands only

| Layer | Owns |
|-------|------|
| `scripts/sim/` | World state, rules, ticks, save snapshots |
| `scripts/view/` | Map, HUD, input, sprites, audio |

Presentation may call `CommandManager.execute(...)`, read sim state, and listen to `MessageBus`. It must not call `inventory.alter` on authoritative sim state except in dev-only debug tools.

## Audit summary (Phase Zero)

### Playable today

- **Headless sim:** `GameSession`, production, collectors, buildability, JSON snapshot v3, 28/28 building integration waves.
- **PoC scene:** `scenes/poc_main.tscn` — test map, build palette, placement via `BuildCommand`, sim clock, HUD, save/load.
- **Not playable:** Full UH campaign, ship/found-settlement, legacy GUI suite (~30 pytest modules deferred).

### Ported vs partial vs missing

| Genuinely ported | Partial / stub | Missing / XL |
|------------------|----------------|--------------|
| Scheduler, storage, production, commands | SQLite subset via `OS.execute` (desktop only) | Real map DB load |
| JSON save v3 + tests | 5-building gfx slice + placeholders | MP / server |
| Parity harness + golden traces | Minimal HUD | Full GUI parity |

### Headless sim

Yes — GUT and `parity_runner.tscn` run without the main visual scene.

### Save/load

| Path | Status |
|------|--------|
| JSON `user://poc_snapshot.json` + file export/import | PoC + tests |
| Legacy `.sqlite` | Subset building replay (desktop) |
| Browser | `user://` (IndexedDB) + download/upload JSON |

### Content reuse

YAML under `legacy/content/` → `development/godot/export_content.py` → `resources/exported/` + `game_constants.gd`. Gfx via `export_gfx.py` and `BuildingVisualRegistry`. Optional DLC pack `resources/dlc/northern_company/`.

### Web export

Reproducible via `./godot/export_web.sh` → `build/web/`. See [WEB_DEPLOYMENT.md](WEB_DEPLOYMENT.md).

### Parity confidence

196+ GUT tests; 12 parity scenarios vs golden traces (legacy Python optional when `fife` is installed). Demo slices under `resources/demo/` mirror key parity scenarios.

### Architectural risks

1. Web vs desktop API gaps (`OS.execute`, SQLite import).
2. Sim tick must stay independent of frame rate (`SimClock`).
3. Export bundle size (full `buildings.json`; trim later if needed).
4. Accidental UI shortcuts bypassing commands.

## Milestones

| ID | Goal | Exit criteria |
|----|------|----------------|
| **M0** | Roadmap + README accuracy | This doc; README matches PoC controls |
| **M1** | Browser build | `export_web.sh`, preset, WEB_DEPLOYMENT, smoke checklist |
| **M2** | Economic loop | Lumberjack + trees → boards; save round-trip; integration test; browser saves |
| **M3** | Sim/view boundaries | No prod `alter` in view; `SimClock`; rules documented |
| **M4** | Data-driven + theme | `validate_content.py` in sync/CI; theme pack demo |
| **M5** | Save integrity | SAVE_FORMAT.md, migration hook, `snapshot_roundtrip` parity |
| **M6** | Living world (design) | Sections below — no large implementation |
| **M7** | Legacy save import experiment | **Archived / maintenance-only** — PoC import + fixture regression guards; no new parity scope — [`M7_LEGACY_SAVE.md`](M7_LEGACY_SAVE.md), [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md) |
| **M8** | Godot-native play | Demo loop polished; JSON save/load in demo + browser; extend Godot-only parity scenarios; PORT_CHECKLIST refresh; view/content tiers — see [M8 backlog](#m8--godot-native-play-backlog) |

## M8 — Godot-native play (backlog)

Ordered work after the Godot-first policy merge. **Out of scope** until reconsidered: settler upgrade chains for legacy saves, ships/paths sqlite fidelity, rev-76 full T1b, T1m dual-run as a blocker, reverse sqlite export, multiplayer sync.

| Priority | Work | Anchors |
|----------|------|---------|
| **P0** | Playable demo polish — objective clarity, JSON save/load in flow, status/errors | **Done (2026-10):** HUD hints, Continue menu refresh, load status with demo step |
| **P1** | Web parity with desktop demo — `.extract.json` or JSON-only path documented; no new sqlite on web | **Done (2026-10):** browser `.extract.json` import + BROWSER/WEB checklists |
| **P2** | Parity scenarios (Godot-only goldens) — extend stage 3 chains per [`development/godot/parity/README.md`](../../development/godot/parity/README.md) | **Done (2026-10):** `weaver`, `salt_ponds` + goldens |
| **P3** | PORT_CHECKLIST refresh — sync checkboxes with GUT/parity truth | **Done (2026-10):** Appendix C/D, tier-2 chain rows, `report_matrix.py` |
| **P4** | View/content — external port tiers ([`EXTERNAL_GODOT_PORT.md`](EXTERNAL_GODOT_PORT.md)), gfx slice, HUD gaps | |

## Future ideas (historical — cross-engine)

These described a **Python/FIFE ↔ Godot** cutover gate. Under Godot-first they are **not blockers**; kept for context and optional one-way legacy import experiments.

### Legacy save fidelity (Python → Godot)

- **Goal:** Open real **original-game savegames** (`.sqlite` / legacy format) in Godot and continue playing with the same settlement state that matters for gameplay (map, buildings, inventories, production state, settlers/units as they are ported).
- **Today:** Desktop **partial** load test-gated on in-repo fixtures (T1b/T1k/T1n/T1l); PoC HUD shows import summary via `SqliteImportReport.summarize_for_hud()`; web via `.extract.json`. Tracker: [`M7_LEGACY_SAVE.md`](M7_LEGACY_SAVE.md).
- **Tests to add:** A growing **fixture library** of authentic saves (small → large); for each fixture, assert key invariants after load (building counts, resource totals, tick/time, selected world ids). Failures mean the Godot sim is still missing rules or export mappings.
- **Smooth transition:** Document a player workflow: *save in Python → copy file → load in Godot* (and later the reverse once Godot can write compatible saves or an documented interchange format exists).

### Cross-version play (Python + Godot in one world)

- **Goal:** Before moving on to unrelated big features, prove **mixed clients**: one player on the **legacy Python** build and another on the **Godot** build in the **same** session or shared world (observe the same sim truth, submit compatible commands).
- **Why it matters:** Forces agreement on commands, ticks, entity ids, and network/state sync—not just single-player parity traces.
- **Likely shape:** Aligns with [Future server direction](#future-server-direction-design-only)—authoritative sim, versioned command envelope, clients are thin. Mixed-engine play is an **acceptance test** for that design, not a one-off hack.
- **Pragmatic staging:**
  1. Same save loads in both engines; manual QA on identical scenario steps (dual-run parity extended to full saves).
  2. Hot-join or sync via a small relay/server (out of scope until single-player legacy load is trustworthy).
  3. Only then: declare Godot ready to replace Python for multiplayer scenarios.

### Exit criteria (proposal — do not skip)

| Criterion | Meaning |
|-----------|---------|
| Fixture saves load in Godot | No silent data loss; explicit errors for unsupported fields |
| Python → Godot → play | Player can continue a campaign slice without debug cheats |
| Parity on loaded state | After load, run N ticks; compare traces or inventories vs golden |
| Cross-version session (stretch) | Python + Godot clients stay in sync on a test map |
| Reverse path (stretch) | Godot save or export readable by Python, or documented migration only |

Stretch rows are **not scheduled** (see [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md)). Historical tracker: [`M7_LEGACY_SAVE.md`](M7_LEGACY_SAVE.md).

See also [MIGRATION_STRATEGY.md](MIGRATION_STRATEGY.md).

## Browser blockers (living list)

| Blocker | Status |
|---------|--------|
| No export preset / script | **Resolved** — M1 |
| Forward+ without Compatibility on web | **Resolved** — web preset uses Compatibility |
| SQLite `OS.execute` on WASM | **Resolved** — gated on `OS.has_feature("web")` |
| Ephemeral saves only | **Mitigated** — download/upload JSON in PoC |
| No automated browser CI | **Open** — manual smoke in WEB_DEPLOYMENT |
| Full game content size | **Open** — monitor PCK size |

## M2 — Economic loop (assessment)

**Target loop:** map → palette → place lumberjack → place trees → clock runs → collector/production → boards in storage → HUD updates → save → reload.

**Legitimate path:** `BuildCommand` for lumberjack and `TREE`; production/collector sim (see `test_lumberjack` in `test_buildings_wave_f1.gd`).

**Remaining polish:** onboarding hint in HUD; dev-only resource debug panel.

## M5 — Determinism notes

- Parity scenarios use **ticks** / `run_seconds` (16 ticks/s), not wall clock in sim.
- Sources of nondeterminism: RNG (when used), hash iteration order, `finish_production_now()` in tests only.
- Cross-platform deterministic replay is **not** claimed until measured.

## M6 — Living world (future design)

### Individuals (future `scripts/sim/agents/`)

- Needs, skills, home/workplace, schedules, relationships.
- Decision logic: explicit state machines + unit tests; **no LLM in core sim**.

### Economy (extend existing storage/production)

- Supply/demand, shortages, trade routes, labour allocation on top of `Inventory` / collectors.

### Factions (future)

- Settlement identity, diplomacy, territory — command-validated, snapshot-serializable.

### Performance

- Tick scheduling (`GameScheduler`), event-driven updates, coarser sim for distant settlements when needed.
- No multithreaded sim or distributed workers in near term.

## Future server direction (design only)

```mermaid
sequenceDiagram
  participant Browser
  participant Server
  Browser->>Server: PlayerCommand JSON
  Server->>Server: Validate and execute on GameSession
  Server->>Browser: StateDelta or snapshot chunk
```

- Server owns authoritative `GameSession`; clients render and submit commands (same shape as `CommandManager`).
- Persistent worlds and multi-client observe later; **no** auth/DB/MP in current milestones.
- First browser build stays **single-player**, static hosting.

## Related work (upstream Godot port)

The official [unknown-horizons/godot-port](https://github.com/unknown-horizons/godot-port) project targets full game presentation (UI, maps, building scenes). We cherry-pick **assets and view patterns** only; sim rules stay here.

See [EXTERNAL_GODOT_PORT.md](EXTERNAL_GODOT_PORT.md) for **import tiers A/B/C**, allowlist, parity gates, and pinned icon imports.

## Post-merge audit — neglected or stale areas (2026-10-17)

Merged browser demo Phase 1, reskin/export pipeline, and tier-1 scenario work (#17–#20). Remaining gaps worth tracking:

| Area | Notes |
|------|--------|
| **PORT_CHECKLIST body** | **2026-10 P3 refresh** — Appendix C/D + tier-2 chains + Phase 0.5 demo; XL/deferred rows still `[ ]` by design. Use `./development/godot/report_matrix.py` for counts. |
| **PoC SQLite import** | Desktop FileDialog import wired; browser remains JSON-only. |
| **`report_matrix.py`** | Lists GUT-only demo/sqlite files; run after major test additions. |
| **Automated browser QA** | CI builds web + **shareable-demo-screenshot** PNG artifact; no in-browser playtest yet. |
| **Legacy GUI pytest (~30)** | Still deferred; PoC HUD is not full ingame GUI parity. |
| **Stale git branch** | Delete `origin/cursor/belief-batch-4931` when confirmed obsolete. |
| **Legacy sqlite import (M7)** | Frozen experiment; JSON v3 is canonical — [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md). |

Hygiene fixes from this audit: doc test/parity counts, `export_web.sh` → `export_all.sh`, parity README CI blurb, EXPORT_PIPELINE A1 status.

## Related docs

- [EXTERNAL_GODOT_PORT.md](EXTERNAL_GODOT_PORT.md)
- [WEB_DEPLOYMENT.md](WEB_DEPLOYMENT.md)
- [SAVE_FORMAT.md](SAVE_FORMAT.md)
- [SCAFFOLDING.md](SCAFFOLDING.md)
- [PORT_CHECKLIST.md](../PORT_CHECKLIST.md)
- [development/godot/parity/README.md](../../development/godot/parity/README.md)

## Stable identifiers vs display names

- Simulation uses numeric IDs from `GameConstants` (e.g. `BUILDINGS.LUMBERJACK`) and export **stems** (`lumberjackcamp`).
- YAML `id` / `id_name` map to those constants at export time.
- Player-visible names live in content packs / UI JSON (`ContentTheme`), never as sim dictionary keys.

## Theme / reskin workflow

1. Set `resources/exported/active_theme.json` → `{ "pack_id": "northern_company" }` (or empty for default).
2. Reload PoC — palette labels and building tints use pack metadata (sim rules unchanged).
3. See `resources/dlc/northern_company/` for the reference pack.
