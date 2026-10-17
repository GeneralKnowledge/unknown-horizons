# Godot port — task checklist

Tick items by changing `[ ]` to `[x]` in this file (works in GitHub, editors, and many markdown viewers).

## Difficulty legend

| Label | Meaning |
|-------|---------|
| **S** | Small — clear Python reference + existing pytest; mostly straight translation |
| **M** | Medium — several classes or non-obvious edge cases |
| **L** | Large — subsystem with many touchpoints or weak test coverage |
| **XL** | Extra large — engine/UI/MP rewrite; plan carefully before coding |

**How to use “Approach”:** Prefer port **sim first, view second**. For each row, add a GUT test copied from the linked Python test before or right after the port.

---

## Phase 0 — PoC (done)

- [x] **Godot 4 project scaffold** (S) — `project.godot`, sim/view folders, content symlink.  
  *Approach:* Keep all gameplay logic in `RefCounted` / plain classes under `scripts/sim/`.

- [x] **GUT + headless CI** (S) — `addons/gut`, `.gutconfig.json`, `run_tests.sh`, GitHub workflow.  
  *Approach:* Run `./godot/run_tests.sh` locally before every PR; mirror pytest names where possible.

- [x] **Content export bridge** (M) — `development/godot/export_content.py` → `game_constants.gd`, `buildings.json`.  
  *Approach:* Extend export script when adding new YAML-driven types; avoid hand-editing generated files.

- [x] **Scheduler port** (M) — `scripts/sim/game_scheduler.gd` ← `horizons/scheduler.py`.  
  *Approach:* `tests/unittests/test_scheduler.py` → `tests/unit/test_scheduler.gd` (subset done; add remaining cases).

- [x] **Storage + production line port** (M) — inventory types, `ProductionLine`.  
  *Approach:* `tests/unittests/world/test_storage.py`, `test_productionline.py` → expand GUT coverage beyond PoC subset.

- [x] **Production + producer (lumberjack)** (L) — `Production`, `Producer`, pause/active state.  
  *Approach:* Match `horizons/world/production/production.py` listener/pause semantics; integration test is the guardrail.

- [x] **GameSession + Build (minimal)** (M) — settle + place lumberjack only.  
  *Approach:* `tests/game/test_production.py` → `tests/integration/test_wood_production.gd`.

- [x] **Minimal playable scene** (S) — `scenes/poc_main.tscn`, debug HUD.  
  *Approach:* Scene only calls sim APIs (`BuildCommand`, `run_ticks`); no rules in the view layer.

---

## Phase 1 — Simulation core (test-driven)

### Time and commands

- [ ] **Timer / real-time tick driver** (M) — wall clock → ticks like `horizons/timer.py`.  
  *Approach:* Optional autoload that accumulates `delta` and calls `GameScheduler.tick`; port `tests/unittests/test_timer.py`.

- [ ] **Command manager (SP)** (M) — execute `Build`, `Tear`, transfers like `horizons/manager.py` / `command/`.  
  *Approach:* Single queue executed on tick boundaries; each command is a `Callable` or small class with `execute(session, player)`.

- [ ] **Full scheduler test parity** (S) — all cases in `tests/unittests/test_scheduler.py`.  
  *Approach:* Copy remaining tests one-by-one; fix scheduler until green.

- [ ] **Full storage test parity** (M) — `PositiveTotalStorage`, slots, settlement storage, etc.  
  *Approach:* Port remaining classes from `horizons/world/storage.py`; one GUT file per Python test class.

### World graph

- [ ] **WorldObject registry** (M) — IDs, lookup, delete ← `horizons/util/worldobject.py`.  
  *Approach:* Central `EntityRegistry` autoload or session-owned dict; used by commands and save/load later.

- [ ] **World / island / settlement (real maps)** (L) — load tile grid, not empty session ← `horizons/world/`.  
  *Approach:* Start from `tests/game/utils.py` `create_map()` logic; SQLite map DB or exported tile JSON for Godot tests.

- [ ] **Component holder + YAML entity types** (L) — ← `componentholder.py`, `ingametype.py`, `entities.py`.  
  *Approach:* Either runtime YAML parse in GDScript or extend `export_content.py` to emit component graphs; map component names to GDScript classes (as PoC does for Storage/Producer).

- [ ] **Build command (full rules)** (L) — buildability, settlement, ship distance ← `command/building.py`.  
  *Approach:* Depends on buildability caches + `Entities`; port `tests/game/test_buildings.py` incrementally.

- [ ] **Settlement range** (M) — warehouse/lookout expansion ← settlement/buildability.  
  *Approach:* `tests/game/test_settlement_range.py` after basic `Build` works on a real map.

### Production economy (beyond lumberjack)

- [ ] **Producer utilization + status hooks** (M) — `FieldUtilization`, productivity icons (sim-only flags first).  
  *Approach:* Port `utilization.py`; defer FIFE icons until view layer; use bool flags on building for tests.

- [ ] **Multiple production lines / queue producer** (M) — boat builder, settlers ← `QueueProducer`, `SingleUseProduction`.  
  *Approach:* Subclass or strategy on `Production`; add one building per test file from `tests/game/`.

- [ ] **Resource providers / trade routes** (L) — `providerhandler`, `traderoute.py`.  
  *Approach:* `tests/game/test_traderoute.py`; collectors must exist first.

---

## Phase 2 — Buildability and units (large, well-tested in Python)

### Buildability caches

- [ ] **Connected area cache** (M) — `world/buildability/connectedareacache.py`.  
  *Approach:* `tests/unittests/world/buildability/test_connectedareacache.py` first; pure grid math, no rendering.

- [ ] **Partial binary / terrain / settlement caches** (L) — remaining `world/buildability/*`.  
  *Approach:* One cache class + one GUT file per Python test module; share a tiny grid fixture helper.

- [ ] **Tile / road orientation** (S) — `util/tile_orientation.py`.  
  *Approach:* `tests/unittests/util/test_tile_orientation.py` → `tests/unit/test_tile_orientation.gd`.

### Pathfinding and collectors

- [ ] **Pathfinding** (L) — `util/pathfinding/*`.  
  *Approach:* Port `pathnodes` + `pathfinder` with grid fixtures; no FIFE.

- [ ] **Collector units** (L) — lumberjack collector loop ← `units/collectors/`.  
  *Approach:* `tests/unittests/world/units/collectors/test_collector.py`; integrate with building `CollectingComponent` from YAML.

- [ ] **Ships + movement** (L) — `movingobject`, `ship.py`.  
  *Approach:* Scheduler `_move_tick` callbacks; view sync later.

---

## Phase 3 — Presentation and content pipeline

- [ ] **Isometric map view** (L) — `TileMapLayer` or custom mesh; camera ← `horizons/view.py` behavior only.  
  *Approach:* Hard-code tile size to match FIFE; load one dev map; click → grid coord → `BuildCommand`.

- [ ] **Building sprites / animation** (XL) — replace FIFE action sets ← `content/gfx/`, SQLite atlases.  
  *Approach:* PoC path: `AnimatedSprite2D` + folder of PNGs for one action set; long-term: batch script `content/gfx` → Godot `SpriteFrames` (skip `sqliteatlasloader` in engine).

- [ ] **Runtime YAML loading (optional)** (M) — reduce reliance on JSON export.  
  *Approach:* Embed lightweight YAML parser addon or pre-import all objects at export time; keep `game_constants.gd` generated.

- [ ] **Map load from UH SQLite** (L) — `content/maps/`, `map-template.sql`.  
  *Approach:* Godot SQLite plugin read-only in tool script, or Python export maps to JSON for Godot builds.

- [ ] **Audio** (M) — ← `horizons/engine/sound.py`, `content/audio/`.  
  *Approach:* Godot `AudioStreamPlayer`; trigger from sim events via signals.

---

## Phase 4 — Meta systems

- [ ] **Save / load (subset)** (XL) — `savegamemanager.py`, DB schema.  
  *Approach:* Start with `tests/game/test_load_save.py` minimal case; versioned schema; sim-only save without GUI.

- [ ] **Scenario / conditions** (L) — `horizons/scenario/`.  
  *Approach:* Data-driven triggers on scheduler ticks; port tutorial YAML actions one at a time.

- [ ] **Disasters** (M) — fire, black death ← `world/disaster/`.  
  *Approach:* `tests/game/test_fire.py`, `test_blackdeath.py`.

- [ ] **Combat** (L) — units, weapons ← `tests/game/test_combat.py`.  
  *Approach:* Sim combat resolution first; animation later.

- [ ] **Settlers / happiness** (L) — `tests/game/test_settler.py`, settler production classes.  
  *Approach:* `SettlerProduction` behavior in GDScript after base `Production` stable.

- [ ] **AI player** (XL) — `horizons/ai/`.  
  *Approach:* Defer until commands + economy stable; reuse long Python tests as acceptance targets.

- [ ] **Multiplayer lockstep** (XL) — `network/`, tick-synced commands ← `mpsession.py`.  
  *Approach:* Same command objects serialized per tick; Godot multiplayer or external server; port `tests/unittests/mp/*` last.

---

## Phase 5 — UI and product parity

- [ ] **In-game HUD shell** (XL) — replace PyChan ← `horizons/gui/ingamegui.py`.  
  *Approach:* Godot Control tree; one tab at a time (warehouse, production); do not port XML literally—match behavior.

- [ ] **Main menu + singleplayer flow** (L) — `gui/modules/singleplayermenu.py`.  
  *Approach:* Scene flow: menu → map select → `GameSession.load_map`.

- [ ] **Mouse tools** (L) — build, select, tear ← `gui/mousetools/`.  
  *Approach:* State machine on input; calls same commands as tests.

- [ ] **GUI automated tests** (XL) — `tests/gui/*` (FIFE-specific).  
  *Approach:* Re-spec as GUT scene tests or Godot `SceneTree` input simulation; lowest priority.

- [ ] **i18n** (M) — gettext / `po/` ← `horizons/i18n/`.  
  *Approach:* Godot translation CSV or gettext import; reuse `po/` files.

- [ ] **Editor** (XL) — `horizons/editor/`.  
  *Approach:* Optional; separate tool project or disabled until game playable.

---

## Phase 6 — Quality and migration

- [ ] **Expand GUT coverage tracker** (S) — table mapping pytest → GUT files.  
  *Approach:* Add a column to this doc or `tests/README.md` in `godot/tests/`.

- [ ] **Fix GUT / Godot version pin in CI** (S) — document 4.3 vs 4.4 + GUT compatibility.  
  *Approach:* Match local `run_tests.sh` and workflow; avoid enabling broken editor plugin on CLI-only runs.

- [ ] **Performance baseline** (M) — tick cost on large maps.  
  *Approach:* Headless benchmark scene; compare tick time vs Python SP session on same map export.

- [ ] **Decide monolith vs dual-run** (S) — shipping strategy.  
  *Approach:* Document whether Godot replaces FIFE entirely or runs parallel until feature parity.

---

## Suggested order (if unsure what to pick next)

1. Full **scheduler** + **storage** test parity (cheap confidence).  
2. **Buildability caches** + **Build** on real map (`test_buildings`, `test_settlement_range`).  
3. **Collectors** + **pathfinding** (gameplay loop).  
4. **Isometric view** wired to commands.  
5. Save/load subset → scenarios → UI shell.

---

*Last updated: PoC merge baseline (lumberjack + 8 GUT tests).*
