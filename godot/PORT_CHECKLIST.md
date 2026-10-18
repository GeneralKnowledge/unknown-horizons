# Godot port — detailed task checklist

Tick items: `[ ]` → `[x]`.

**Table of contents:** [Legend](#legend) · [Phase 0 (PoC)](#phase-0--poc-done) · [Phase 1 Sim](#phase-1--simulation-core) · [Phase 2 World](#phase-2--world-buildability-units) · [Phase 3 View](#phase-3--presentation--content) · [Phase 4 Meta](#phase-4--meta-systems) · [Phase 5 UI](#phase-5--ui) · [Phase 6 Quality](#phase-6--quality--migration) · [Components](#appendix-a--component-port-list) · [Commands](#appendix-b--command-port-list) · [Coverage matrix](#appendix-c--pytest--gut-coverage-matrix) · **[GUI detail (per test)](PORT_CHECKLIST_GUI.md)**

---

## Legend

### Difficulty (letter)

| Label | Meaning |
|-------|---------|
| **S** | Small — single class or test; straightforward port |
| **M** | Medium — multiple types or subtle behavior |
| **L** | Large — subsystem; many callers |
| **XL** | Extra large — cross-cutting; weak tests or heavy FIFE coupling |

### Effort (stars)

| Stars | Typical scope |
|-------|----------------|
| ★☆☆☆☆ | Minutes–hours; one function or test case |
| ★★☆☆☆ | Hours; one class |
| ★★★☆☆ | Days; small module + tests |
| ★★★★☆ | Days–weeks; module graph |
| ★★★★★ | Weeks+; platform or full UI/MP |

### Task fields

- **Python** — source of truth in this repo  
- **Godot** — target script (create if missing)  
- **Test** — pytest to port; **GUT** = target file under `godot/tests/`  
- **Blocked by** — do not start until those items are done  
- **Approach** — how to implement without re-coupling to FIFE

**Rule:** Port sim logic as plain GDScript (`RefCounted`); view layer only observes sim state and sends commands.

---

## Phase 0 — PoC (done)

- [x] **Project scaffold** — ★★☆☆☆ (S)  
  - **Godot:** `project.godot`, `scripts/sim/`, `scripts/view/`, `resources/content` → `../../content`  
  - **Approach:** No gameplay rules in scenes; autoload only for constants.

- [x] **GUT + CI** — ★★☆☆☆ (S)  
  - **Godot:** `addons/gut/`, `.gutconfig.json`, `run_tests.sh`, `.github/workflows/godot-tests.yml`  
  - **Approach:** CLI only (`gut_cmdln.gd`); editor plugin optional.

- [x] **Export script (buildings + constants)** — ★★★☆☆ (M)  
  - **Python:** `development/godot/export_content.py`, `horizons/constants.py`, `content/objects/buildings/*.yaml`  
  - **Godot:** `scripts/autoload/game_constants.gd`, `resources/exported/buildings.json`  
  - **Approach:** Re-run export after YAML changes; resolve `RES.*` tokens to numeric IDs in export.

- [x] **Scheduler (core)** — ★★★☆☆ (M)  
  - **Python:** `horizons/scheduler.py`  
  - **Godot:** `scripts/sim/game_scheduler.gd` (inner `SchedulerCallback`)  
  - **Test:** `tests/unittests/test_scheduler.py` → `tests/unit/test_scheduler.gd` *(partial)*  
  - **Approach:** Match tick ordering (`popleft`, same-tick `run_in=0` queue).

- [x] **Storage (subset) + production line** — ★★★☆☆ (M)  
  - **Python:** `horizons/world/storage.py`, `horizons/world/production/productionline.py`  
  - **Godot:** `scripts/sim/storage/*`, `scripts/sim/production_line.gd`  
  - **Test:** partial `test_storage.py`, `test_productionline.py` → unit GUT  
  - **Approach:** Use `amount(res)` not `get()` — clashes with `Object.get`.

- [x] **Production + Producer** — ★★★★☆ (L)  
  - **Python:** `horizons/world/production/production.py`, `producer.py`  
  - **Godot:** `scripts/sim/production.gd`, `producer.gd`  
  - **Approach:** Inventory change listeners drive state; scheduler for produce duration.

- [x] **GameSession + minimal Build** — ★★★☆☆ (M)  
  - **Python:** `tests/game/__init__.py` (`SPTestSession`), `command/building.py` *(partial)*  
  - **Godot:** `scripts/sim/game_session.gd`, `scripts/sim/commands/build_command.gd`  
  - **Test:** `tests/game/test_production.py` → `tests/integration/test_wood_production.gd` ✓  
  - **Blocked by:** export for lumberjack YAML (production line id = SHA1 of `"BOARDS"` → `256812226`).

- [x] **PoC scene** — ★★☆☆☆ (S)  
  - **Godot:** `scenes/poc_main.tscn`, `scripts/view/poc_main.gd`  
  - **Approach:** Fixed tick rate `1/16 s`; Space/Enter cheat inputs into storage.

### Phase 0.5 — Browser demo & shareable showcase

- [x] **Start menu + demo_config.json** — ★★☆☆☆ (S)  
  - **Godot:** `start_menu_panel.gd`, `demo_config.gd`, `resources/demo/demo_config.json`  
- [x] **Showcase demo (tier-1 scenario)** — ★★☆☆☆ (S)  
  - **Godot:** `demo_scenario_runner.gd`, `starter_tier1_scenario.json`, start menu **Play showcase demo**  
- [x] **Shareable screenshot scene** — ★★☆☆☆ (S)  
  - **Godot:** `scenes/shareable_demo.tscn`, `development/godot/capture_shareable_demo.sh`  
- [x] **JSON save import/export in PoC** — ★★☆☆☆ (S)  
- [x] **Legacy SQLite import UI (desktop)** — ★★★☆☆ (M)  
  - **Godot:** FileDialog filters + `SaveLoader` / `SqliteSaveLoader` from start menu & HUD  
- [x] **Northern Company reskin pack** — ★★★☆☆ (M)  
  - **Docs:** `EXPORT_PIPELINE.md`, `resources/dlc/northern_company/`  
- [x] **Web export CI + parity-golden CI** — ★★☆☆☆ (S)  
  - **Workflow:** `.github/workflows/godot-tests.yml` (`gut`, `parity-golden`, `web-export`)

---

## Phase 1 — Simulation core

### 1.1 Content pipeline (extend export)

- [x] **Export units + grounds YAML (PoC slice)** — ★★★☆☆ (M)  
  - **Python:** `export_grounds.py`, `export_maps.py`, `export_unit_gfx.py`  
  - **Godot:** `resources/maps/`, `resources/gfx/units/`  
  - **Approach:** Full entity graph still deferred; maps/grounds/unit gfx wired in CI/sync.

- [x] **Export production line name → id map** — ★☆☆☆☆ (S)  
  - **Output:** `resources/exported/production_line_ids.json` (from YAML keys via SHA1 % 2³¹).

- [ ] **Export `game.sql` tables used at runtime** — ★★★★☆ (L)  
  - **Python:** `content/game.sql`, `horizons/util/dbreader.py`  
  - **Godot:** JSON blobs or Godot SQLite read-only  
  - **Approach:** Start with tables needed for `Entities.load` (buildings/units metadata), not full DB.

- [x] **Symlink / path docs for CI** — ★☆☆☆☆ (S)  
  - **Docs:** `README.md`; workflow runs `export_content.py` before GUT.

### 1.2 Timer and tick driver

- [x] **Port wall-clock tick driver (`GameClock`)** — ★★★☆☆ (M)  
  - **Godot:** `scripts/sim/game_clock.gd` (injectable time source; no FIFE pump).

- [ ] **GUT: `test_activate_register_end_unregister_from_pump`** — ★★☆☆☆ (S) *(FIFE-specific; N/A)*  

- [x] **GUT: `test_first_pump_then_one_tick`** — ★★☆☆☆ (S) → `tests/unit/test_game_clock.gd`  
- [x] **GUT: `test_two_pump_same_time_only_one_tick`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_two_pump_with_delay_then_two_ticks`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_two_pump_close_in_time_then_only_one_tick`** — ★★☆☆☆ (S)  
- [ ] **GUT: `test_fast_pumping_only_tick_alternately`** — ★★★☆☆ (M)  
- [x] **GUT: `test_slow_pump_multiple_ticks`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_paused_pump_then_no_ticks`** — ★★☆☆☆ (S)  
- [ ] **GUT: `test_pause_pump_unpack_pump`** — ★★★☆☆ (M)  
- [ ] **GUT: `test_pause_on_callback`** — ★★★☆☆ (M)  
- [ ] **GUT: `test_freeze_protection`** — ★★★☆☆ (M) *(optional for SP-only Godot)*  
- [x] **GUT: `test_pump_test_func_skip`** — ★★★☆☆ (M)  
- [ ] **GUT: `test_pump_test_func_pass`** — ★★★☆☆ (M) *(MP-related)*  

### 1.3 Scheduler — full pytest parity

*Godot:* `scripts/sim/game_scheduler.gd` · *GUT:* `tests/unit/test_scheduler.gd` · **`can_tick()`** for invalid-tick checks

- [x] **GUT: `test_create_then_register_with_timer`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_end_then_unregister_from_timer`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_multiple_sequential_ticks`** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_fail_when_missing_start_tick`** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_fail_when_same_tick_twice`** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_add_callback_before_first_tick`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_add_callback_run_in_1_on_first_tick`** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_add_callback_only_triggered_once`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_started_ticking_then_add_callback_for_next_tick`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_started_ticking_then_add_callback_for_future`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_within_callback_add_new_callback_for_same_tick`** — ★★★☆☆ (M)  
- [x] **GUT: `test_within_callback_add_new_callback_for_future_tick`** — ★★★☆☆ (M)  
- [x] **GUT: `test_add_periodic_callback_called_every_tick_3_times`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_add_periodic_callback_run_every_other_tick_3_times`** — ★★★☆☆ (M)  
- [x] **GUT: `test_remove_call_from_instance`** — ★★★☆☆ (M)  
- [x] **GUT: `test_list_and_manually_remove_all_classinstance_callbacks`** — ★★★☆☆ (M)  
- [x] **GUT: `test_remove_all_classinst_calls`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_get_remaining_ticks`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_get_remaining_tick_periodic_callback`** — ★★★☆☆ (M)  
- [x] **GUT: `test_get_ticks_of_month`** — ★☆☆☆☆ (S)  
- [ ] **Port `rem_object` parity with Python** — ★★★☆☆ (M)  

- [x] **Port `Scheduler.get_ticks_of_month`** — ★☆☆☆☆ (S)  
  - **Godot:** `GameScheduler.get_ticks_of_month()` + `GameTimer.INGAME_TICK_INTERVAL_SECONDS`.

### 1.4 Storage — classes and tests

*Python:* `horizons/world/storage.py` · *Godot:* `scripts/sim/storage/`

| Class (Python) | Godot class | Done |
|----------------|-------------|------|
| `GenericStorage` | `Inventory` | partial |
| `SpecializedStorage` | `SpecializedInventory` | partial |
| `SizedSpecializedStorage` | `SizedSpecializedInventory` | partial |
| `PositiveStorage` | `PositiveInventory` | partial |
| `PositiveSizedSpecializedStorage` | `PositiveSizedSpecializedInventory` | partial |
| `GlobalLimitStorage` | `GlobalLimitInventory` | yes |
| `TotalStorage` | `TotalInventory` | yes |
| `PositiveTotalStorage` | `PositiveTotalInventory` | yes |
| `PositiveSizedSlotStorage` | `PositiveSizedSlotInventory` | yes |
| `PositiveSizedNumSlotStorage` | `PositiveSizedNumSlotInventory` | yes |
| `SettlementStorage` | flag / shared ref | no |

**GUT parity** (`tests/unittests/world/test_storage.py` → `tests/unit/test_storage.gd`):

- [x] **GUT: `test_alter` (generic)** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_reset` / `test_reset_all` / `test_limit` / `test_sum_of_stored_resources` / `test_get_item`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_positive_sized_specialized` (partial)** — ★★☆☆☆ (S)  
- [x] **GUT: `test_specialized` / `test_sized_specialized` (full)** — ★★★☆☆ (M)  
- [x] **GUT: `test_adjust_limit` (`GlobalLimitStorage`)** — ★★★☆☆ (M)  
- [x] **GUT: `test_total` (`TotalStorage`)** — ★★★☆☆ (M)  
- [x] **GUT: `test_positive` / `test_positive_total`** — ★★★☆☆ (M)  
- [x] **GUT: `test_sized_slotted` / `test_positive_sized_num_slot`** — ★★★☆☆ (M)  
- [ ] **`StorageComponent` wrapper** — ★★★☆☆ (M)  
  - **Python:** `horizons/component/storagecomponent.py`  
  - **Approach:** Settlement shared inventory; `something_changed` → production listeners.

### 1.5 Production line and production variants

- [x] **GUT: `test_init`** — ★☆☆☆☆ (S)  
- [x] **GUT: `test_alter_production_time`** — ★★☆☆☆ (S)  
- [x] **GUT: `test_change_amount`** — ★★☆☆☆ (S)  
- [ ] **Production state history / utilization window** — ★★★★☆ (L)  
  - **Python:** `_state_history`, `get_state_history_times`, `PRODUCTION.STATISTICAL_WINDOW`  
  - **Blocked by:** scheduler tick parity  
- [ ] **`ChangingProduction` / save hooks on prod line** — ★★★★☆ (L)  
- [ ] **`SettlerProduction`** — ★★★★☆ (L)  
  - **Test:** `tests/game/test_settler.py`  
- [ ] **`SingleUseProduction` / `QueueProducer`** — ★★★★☆ (L)  
  - **Python:** `producer.py` (`QueueProducer`, boat builder)  
  - **Test:** `tests/gui/ingame/test_boatbuilder.py` *(later)*  
- [ ] **Unit production (`UnitProduction`)** — ★★★★☆ (L)  
  - **Python:** `horizons/world/production/unitproduction.py`  
- [ ] **Gold / `uses_gold` owner inventory** — ★★★☆☆ (M)  
- [ ] **Mine producer / `MineEmpty` path** — ★★★☆☆ (M)  

### 1.6 Producer utilization and status (sim flags)

- [ ] **`Utilization` / `FullUtilization` / `FieldUtilization`** — ★★★☆☆ (M)  
  - **Python:** `horizons/world/production/utilization.py`  
- [ ] **Capacity utilization scheduler tick on producer** — ★★★☆☆ (M)  
  - **Approach:** Skip icons initially; expose `productivity_low: bool` for tests.  
- [ ] **Integration: status icon semantics (sim)** — ★★★★☆ (L)  
  - **Test:** `tests/game/test_status_icons.py` (5 tests)  
  - **Blocked by:** message bus or direct building flags  

### 1.7 Commands and session manager

- [ ] **`Command` base + serialization shape** — ★★★☆☆ (M)  
  - **Python:** `horizons/command/__init__.py`  
- [ ] **`SPManager` execute-now** — ★★★☆☆ (M)  
  - **Python:** `horizons/manager.py`, `horizons/spsession.py`  
  - **Godot:** `scripts/sim/command_manager.gd`  
- [ ] **`Build` full implementation** — ★★★★☆ (L)  
  - **Python:** `horizons/command/building.py`  
  - **Blocked by:** buildability, `Entities`, world registry, tearset  
- [ ] **`Tear` / `Build` tearset** — ★★★☆☆ (M)  
  - **Test:** `tests/game/test_buildings.py::test_build_tear`, `test_remove_buildings.py`  
- [ ] **`CreateUnit` / `RemoveUnit`** — ★★★☆☆ (M)  
  - **Python:** `horizons/command/unit.py`  
  - **Blocked by:** unit entity types, ship on map  
- [ ] **`TransferResource` / uoptions** — ★★★☆☆ (M)  
  - **Python:** `horizons/command/uioptions.py`  
- [ ] **Production commands** — ★★★☆☆ (M)  
  - **Python:** `horizons/command/production.py`  
- [ ] **Diplomacy commands** — ★★★☆☆ (M)  
  - **Python:** `horizons/command/diplomacy.py` · **Test:** combat/diplo tests  

### 1.8 World object model

- [ ] **`WorldObject` registry** — ★★★☆☆ (M)  
  - **Python:** `horizons/util/worldobject.py`  
  - **Godot:** `scripts/sim/world/entity_registry.gd`  
- [ ] **`ConcreteObject` position / rotation (sim only)** — ★★★☆☆ (M)  
  - **Python:** `horizons/world/concreteobject.py` *(strip FIFE `_instance`)*  
- [ ] **`World` + players** — ★★★★☆ (L)  
  - **Python:** `horizons/world/__init__.py`, `player.py`, `diplomacy.py`  
  - **Test:** `tests/unittests/world/test_world.py`  
- [ ] **`Island` ground map** — ★★★★☆ (L)  
  - **Python:** `horizons/world/island.py`, `ground.py`  
  - **Blocked by:** map load  
- [x] **`Settlement` + warehouse seed (PoC)** — ★★★☆☆ (M)  
  - **Godot:** `settlement.gd` + `SettlementBuildabilityCache` warehouse radius (no `_full_island_build`)  
  - **Test:** `GameTestSession`, `test_settlement_buildability.gd`, tier-1 integration  
- [ ] **`Entities` / `IngameType` loading** — ★★★★★ (XL)  
  - **Python:** `horizons/entities.py`, `horizons/world/ingametype.py`, `componentholder.py`  
  - **Approach:** Incremental: hardcode class map for one building → full export-driven factory.  

### 1.9 Shapes and coordinates

- [x] **Port `Point`, `Rect`, `Circle` (core)** — ★★☆☆☆ (S)  
  - **Godot:** `scripts/sim/shapes/sim_*.gd` · **GUT:** `tests/unit/test_shapes.gd` (3/3)  
- [x] **Port `tile_orientation` / road keys** — ★★☆☆☆ (S)  
  - **Godot:** `scripts/sim/tile_orientation.gd` · **GUT:** 5 cases (subset of 9 parametrized pytest cases)  

### 1.10 Messaging (decouple sim from UI)

- [ ] **Message bus (local signals)** — ★★★☆☆ (M)  
  - **Python:** `horizons/messaging/`  
  - **Godot:** `scripts/sim/message_bus.gd` autoload  
  - **Test:** `tests/unittests/test_messages.py`  
  - **Approach:** Replace FIFE broadcasts with Godot signals; same event names where useful.

---

## Phase 2 — World, buildability, units

### 2.1 Buildability caches

*Python dir:* `horizons/world/buildability/`

- [x] **`ConnectedAreaCache` + GUT** — ★★★☆☆ (M)  
  - **Godot:** `scripts/sim/buildability/connected_area_cache.gd` · **GUT:** `tests/unit/test_connected_area_cache.gd`  
  - **Godot:** `scripts/sim/buildability/connected_area_cache.gd`  

- [x] **`PartialBinaryCache` + all 5 GUT cases** — ★★★★☆ (L) **5/5**  
  - **Godot:** `scripts/sim/buildability/partial_binary_buildability_cache.gd` · **GUT:** `tests/unit/test_partial_binary_cache.gd`  
  - **Done:** full parity with `legacy/.../test_partialbinarycache.py` (horizontal/vertical row2, r2x2, r6x6, coords helper)  

- [ ] **`BinaryCache`** — ★★★☆☆ (M)  
- [ ] **`TerrainCache`** — ★★★☆☆ (M)  
- [ ] **`SettlementCache`** — ★★★★☆ (L) **PoC:** radius seed + footprint; **TODO:** `modify_area` + ground map  
- [ ] **`FreeIslandCache`** — ★★★☆☆ (M)  
- [ ] **`SimpleCollectorAreaCache`** — ★★★☆☆ (M)  
- [ ] **`PotentialRoadConnectivityCache`** — ★★★☆☆ (M)  
- [ ] **Wire caches into `Buildable*` checks** — ★★★★★ (XL)  
  - **Python:** `horizons/world/building/buildable.py`  
  - **Test:** `tests/game/test_buildings.py` (placement failures), `test_settlement_range.py`  

### 2.2 Pathfinding

- [ ] **`pathnodes` + grid representation** — ★★★☆☆ (M)  
- [ ] **`pathfinder` / `pather`** — ★★★★☆ (L)  
  - **Python:** `horizons/util/pathfinding/`  
  - **Approach:** Unit tests with tiny grids; no FIFE walkability — use island ground ids.  

### 2.3 Collectors and resource pickup

- [ ] **Collector sort helpers** — ★★★☆☆ (M)  
  - **Test:** 4 tests in `tests/unittests/world/units/collectors/test_collector.py`  
- [x] **`BuildingCollector` / warehouse flow (MVP)** — ★★★☆☆ (M)  
  - **Godot:** `building_collector.gd`, `storage_collector.gd`; GUT + parity `warehouse_collector` / `tier1_starter`  
  - **TODO:** pathfinding, unit visuals, full collector pytest matrix  
- [x] **`CollectingComponent` on buildings (MVP)** — ★★★☆☆ (M)  
  - **Godot:** `collecting_component.gd`, `building_collector.gd` (radius pickup, no pathfinding)  
  - **Export:** `Collecting` + `radius` in `buildings.json`  

### 2.4 Units and movement

- [ ] **`Unit` / `MovingObject` base** — ★★★★☆ (L)  
- [ ] **`Ship` / player ship** — ★★★★☆ (L)  
  - **Test:** settlement setup uses `CreateUnit` in `tests/game/utils.py`  
- [ ] **`GroundUnit` / combat units** — ★★★★☆ (L)  
- [ ] **Scheduler `_move_tick` loops** — ★★★☆☆ (M)  
- [ ] **Weapons / `Fightingship`** — ★★★★☆ (L)  
  - **Test:** `tests/game/test_combat.py`  

### 2.5 Resource flow

- [ ] **`ResourceHandler` / building providers** — ★★★★☆ (L)  
  - **Python:** `horizons/world/resourcehandler.py`, `buildingresourcehandler.py`  
- [ ] **`ProviderHandler` / reach** — ★★★☆☆ (M)  
- [ ] **Trade routes** — ★★★★☆ (L)  
  - **Test:** `tests/game/test_traderoute.py::test_traderoute_basic`  

### 2.6 Game tests — building production chains

*Source:* `tests/game/test_buildings.py` — port as integration GUT once `Build` + map + chains work.

**Tier 1 (early economy)** — ★★★☆☆ (M) each — **ported** via `tests/integration/test_buildings*.gd` + `test_starter_tier1_scenario.gd`  
- [x] `test_lumberjack`  
- [x] `test_hunter`  
- [x] `test_fisherman`  
- [x] `test_tree_wood_production`  
- [x] `test_build_tear`  

**Tier 2 (chains)** — ★★★★☆ (L) each  
- [x] `test_brick_production_chain` *(demo scenario + integration waves; full pytest parity partial)*  
- [ ] `test_tool_production_chain`  
- [ ] `test_weaver_production_chain`  
- [ ] `test_pavilion_production`  
- [ ] `test_farm_crop_production` / `test_farm_animal_production`  
- [ ] `test_school_production`  
- [ ] `test_saltpond_production`  

**Tier 3 (late game)** — ★★★★☆ (L) each  
- [ ] `test_distillery_production_chain` … through `test_barracks_production_chain` *(remaining 15 tests in file)*  

---

## Phase 3 — Presentation & content

### 3.1 Map and camera

- [x] **Load map fixture (20×20 + development)** — ★★★☆☆ (M)  
  - **Godot:** `MapLoader`, `resources/maps/ground/`, `development` + `test_island_20x20`  
  - **Approach:** Exported JSON grounds; not full legacy map DB.  

- [x] **Ground tile rendering (placeholder)** — ★★★☆☆ (M)  
  - **Godot:** `MapView` + exported ground ids  
- [ ] **Isometric projection constants** — ★★★☆☆ (M)  
  - **Python:** FIFE tile sizes in `constants.py` / engine  
- [x] **Camera pan/zoom (match `View`)** — ★★★☆☆ (M)  
  - **Godot:** `MapCameraController` (middle-drag, wheel zoom, fit island)  
  - **Python:** `horizons/view.py` *(behavior only)*  

### 3.2 Buildings and gfx

- [x] **Lumberjack sprite (exported stem slice)** — ★★★☆☆ (M)  
  - **Godot:** `export_gfx.py`, `BuildingVisualRegistry`, DLC pack gfx overrides  
- [ ] **Idle / work action swap from producer state** — ★★★☆☆ (M)  
- [ ] **Batch gfx → `SpriteFrames` tool** — ★★★★★ (XL)  
  - **Python:** `sqliteatlasloader.py`, `actionsetloader.py`  
- [ ] **`InventoryOverlayComponent` visuals** — ★★★★☆ (L)  

### 3.3 Audio

- [x] **Sample effects (export + first-click)** — ★★☆☆☆ (S)  
  - **Godot:** `export_audio.py`, `GameAudioService`  
- [ ] **Full ambient / effect bus** — ★★★☆☆ (M)  
  - **Python:** `horizons/engine/sound.py`, `ambientsoundcomponent.py`  

---

## Phase 4 — Meta systems

### 4.1 Save / load

- [x] **Savegame DB schema subset (partial import + PoC UI)** — ★★★★☆ (L) — **frozen (Godot-first)**; regression tests only ([`LEGACY_IMPORT_FROZEN.md`](docs/LEGACY_IMPORT_FROZEN.md))  
  - **Godot:** `sqlite_save_loader.gd`, production/collector/settlement restore, trust placement, ships/`LegacyUnit`, `.extract.json` bundles, settler meta, in-flight collector jobs (load + sim deposit), T1b–T1l GUT / M7 multi-fixture storage + tick-128 golden ([`M7_LEGACY_SAVE.md`](docs/M7_LEGACY_SAVE.md)), start menu + HUD FileDialog, fixture matrix CI  
- [ ] **Savegame DB schema subset (full fidelity)** — ★★★★★ (XL) — **N/A (Godot-first)**; use JSON v3 + sim features instead  
- [x] **GUT: `test_load_inactive_production`** — `test_session_save.gd`  
- [x] **GUT: `test_load_producing_lumberjack` (+ mid-production)** — `test_session_save.gd`, `test_sqlite_production_restore.gd`  
- [ ] **GUT: `test_hunter_save_load` / settler save tests** — ★★★★★ (XL) — **JSON v3 path**; legacy sqlite settler depth **frozen**  
- [ ] **GUT: `test_savegame_upgrade`** — ★★★★☆ (L) — **N/A for sqlite expansion**  
- [ ] **Long: `tests/game/long/test_load_save_long.py`** — ★★★★★ (XL) — **FIFE/legacy reference**; Godot equivalent via JSON + GUT  

### 4.2 Scenarios

- [ ] **Condition / action registry** — ★★★★☆ (L)  
  - **Python:** `horizons/scenario/conditions.py`, `actions.py`  
- [ ] **Tutorial YAML (`content/scenarios/tutorial_lt.yaml`)** — ★★★★★ (XL)  
  - **Test:** `tests/gui/scenarios/test_tutorial.py` *(re-spec)*  

### 4.3 Disasters

- [ ] **Fire disaster** — ★★★☆☆ (M) · **Test:** `test_fire_destroy`, `test_fire_station`, `test_upgrade_disallowed_with_fire`  
- [ ] **Black death** — ★★★☆☆ (M) · **Test:** `test_blackdeath_destroy`  

### 4.4 Combat and diplomacy

- [ ] **All `tests/game/test_combat.py` cases (7)** — ★★★★☆ (L) each  

### 4.5 Settlers

- [ ] **`tests/game/test_settler.py` (2 tests)** — ★★★★☆ (L)  

### 4.6 AI

- [ ] **AI quick/long/very long** — ★★★★★ (XL)  
  - **Test:** `tests/game/long/test_ai_*.py`  

### 4.7 Multiplayer

- [ ] **Network packet layout (read-only port)** — ★★★★☆ (L)  
- [ ] **`MPManager` tick-delayed commands** — ★★★★★ (XL)  
  - **Test:** `tests/unittests/mp/test_run_server.py`, `test_server_statistics.py`  

---

## Phase 5 — UI

**Detailed per-file GUI checklist:** [PORT_CHECKLIST_GUI.md](PORT_CHECKLIST_GUI.md) (every `tests/gui/ingame/*.py` test listed with widgets + Godot approach).

### 5.1 Shell and menus

- [ ] **Main menu scene** — ★★★☆☆ (M) · **Python:** `gui/modules/singleplayermenu.py`  
- [ ] **Load/save game UI** — ★★★☆☆ (M)  
- [ ] **Settings / hotkeys** — ★★★★☆ (L) · **Python:** `gui/modules/settings.py`, `hotkeys_settings.py`  
- [ ] **Ingame GUI root** — ★★★★★ (XL) · **Python:** `gui/ingamegui.py`  

### 5.2 Mouse tools (one checkbox each)

- [ ] `navigationtool.py` — ★★★☆☆ (M)  
- [ ] `selectiontool.py` — ★★★☆☆ (M)  
- [ ] `buildingtool.py` — ★★★★☆ (L)  
- [ ] `tearingtool.py` — ★★★☆☆ (M)  
- [ ] `tilelayingtool.py` — ★★★☆☆ (M)  
- [ ] `pipettetool.py` — ★★★☆☆ (M)  
- [ ] `attackingtool.py` — ★★★☆☆ (M)  
- [ ] `cursortool.py` — ★★☆☆☆ (S)  

### 5.3 Tabs / widgets (incremental)

- [ ] **Warehouse / inventory widgets** — ★★★★☆ (L) · **Test:** `tests/gui/ingame/test_warehouse.py`  
- [ ] **Production overview** — ★★★☆☆ (M)  
- [ ] **Build tabs** — ★★★★☆ (L) · **Test:** `tests/gui/ingame/test_build.py`  
- [ ] **Minimap** — ★★★★☆ (L)  
- [ ] **Logbook / messages** — ★★★☆☆ (M)  
- [ ] **Trade / route UI** — ★★★★☆ (L) · **Test:** `tests/gui/ingame/test_traderoute.py`  
- [ ] **Remaining `tests/gui/ingame/*` (15 files)** — ★★★★★ (XL) *(re-spec, not line port)*  

### 5.4 i18n

- [ ] **Import `po/` into Godot translations** — ★★★☆☆ (M)  
  - **Test:** `tests/unittests/test_i18n.py`, `tests/gui/test_unicode.py`  

### 5.5 Editor

- [ ] **Map editor (optional)** — ★★★★★ (XL) · **Python:** `horizons/editor/`  

---

## Phase 6 — Quality & migration

- [x] **Scaffolding guide + sync script** — ★☆☆☆☆ (S)  
  - **Doc:** [`docs/SCAFFOLDING.md`](docs/SCAFFOLDING.md) · **`development/godot/sync.sh`**, `report_matrix.py`, `SaveLoader`  
- [ ] **Maintain Appendix C matrix after each PR** — ★☆☆☆☆ (S) *(run `report_matrix.py`)*  
- [ ] **Pin Godot 4.3 + GUT 9.3 in CI and README** — ★☆☆☆☆ (S)  
- [ ] **Headless benchmark: N ticks on 256×256 map** — ★★★☆☆ (M)  
- [x] **Document dual-run vs cutover strategy** — ★☆☆☆☆ (S)  
  - **Doc:** [docs/MIGRATION_STRATEGY.md](docs/MIGRATION_STRATEGY.md)  
- [ ] **Reduce ObjectDB leaks in GUT teardown** — ★★☆☆☆ (S) *(optional cleanup)*  

---

## Appendix A — Component port list

| Component | Python | Priority | Difficulty | Test |
|-----------|--------|----------|------------|------|
| StorageComponent | `storagecomponent.py` | P0 | ★★★☆☆ (M) | via storage tests |
| Producer (as component) | `producer.py` | P0 | ★★★★☆ (L) | `test_production` ✓ |
| HealthComponent | `healthcomponent.py` | P1 | ★★☆☆☆ (S) | `test_healthcomponent.py` |
| NamedComponent | `namedcomponent.py` | P1 | ★★☆☆☆ (S) | `test_namedcomponent.py` |
| CollectingComponent | `collectingcomponent.py` | P1 | ★★★☆☆ (M) | collector tests |
| SelectableComponent | `selectablecomponent.py` | P2 | ★★☆☆☆ (S) | GUI later |
| TradePostComponent | `tradepostcomponent.py` | P2 | ★★★☆☆ (M) | `test_tradepostcomponent.py` |
| FieldBuilder | `fieldbuilder.py` | P2 | ★★★☆☆ (M) | farm tests |
| DepositComponent | `depositcomponent.py` | P2 | ★★★☆☆ (M) | mine tests |
| InventoryOverlayComponent | `inventoryoverlaycomponent.py` | P3 | ★★★☆☆ (M) | view |
| ColorOverlayComponent | `coloroverlaycomponent.py` | P3 | ★★☆☆☆ (S) | selection |
| AmbientSoundComponent | `ambientsoundcomponent.py` | P3 | ★★☆☆☆ (S) | audio |
| CommandableComponent | `commandablecomponent.py` | P2 | ★★★☆☆ (M) | combat |
| StanceComponent | `stancecomponent.py` | P2 | ★★★☆☆ (M) | combat |
| RestrictedPickup | `restrictedpickup.py` | P3 | ★★☆☆☆ (S) | — |

---

## Appendix B — Command port list

| Command area | File | Difficulty | Typical game test |
|--------------|------|------------|-------------------|
| Build / Tear | `command/building.py` | ★★★★☆ (L) | `test_buildings`, `test_remove_buildings` |
| Units | `command/unit.py` | ★★★☆☆ (M) | settlement setup |
| Production | `command/production.py` | ★★★☆☆ (M) | production chains |
| UI / transfer | `command/uioptions.py` | ★★★☆☆ (M) | warehouse GUI |
| Diplomacy | `command/diplomacy.py` | ★★★☆☆ (M) | `test_combat` |
| Game / misc | `command/game.py`, `misc.py` | ★★☆☆☆ (S) | varies |
| Sounds | `command/sounds.py` | ★★☆☆☆ (S) | optional |

---

## Appendix C — pytest → GUT coverage matrix

| Python test file | GUT file | Status |
|------------------|----------|--------|
| `tests/unittests/test_scheduler.py` (18 tests) | `tests/unit/test_scheduler.gd` | **18/18** ✓ |
| `tests/unittests/test_timer.py` (13 tests) | `tests/unit/test_game_clock.gd` | **13/13** ✓ |
| `tests/unittests/world/test_storage.py` (14 tests) | `tests/unit/test_storage.gd` | **14/14** ✓ |
| `tests/unittests/world/production/test_productionline.py` (3) | `tests/unit/test_production_line.gd` | **3/3** ✓ |
| `tests/game/test_production.py` (1) | `tests/integration/test_wood_production.gd` | **1/1** ✓ |
| `tests/unittests/world/buildability/test_connectedareacache.py` | `tests/unit/test_connected_area_cache.gd` | **1/1** ✓ |
| `tests/unittests/world/buildability/test_partialbinarycache.py` (5) | `tests/unit/test_partial_binary_cache.gd` | **5/5** ✓ |
| `tests/unittests/world/units/collectors/test_collector.py` (4) | `tests/unit/test_collector_job_list.gd` | **4/4** ✓ |
| `tests/unittests/util/test_shapes.py` (3) | `tests/unit/test_shapes.gd` | **3/3** ✓ |
| `tests/unittests/util/test_tile_orientation.py` (9 param) | `tests/unit/test_tile_orientation.gd` | **9/9** ✓ |
| `tests/unittests/world/component/test_healthcomponent.py` (5) | `tests/unit/test_health_component.gd` | **5/5** ✓ |
| `tests/unittests/world/component/test_namedcomponent.py` (6) | `tests/unit/test_named_component.gd` | **6/6** ✓ |
| `tests/unittests/world/component/test_tradepostcomponent.py` (2) | `tests/unit/test_trade_post_component.gd` | **2/2** ✓ |
| `tests/game/test_buildings.py` (28) | `tests/integration/test_buildings_wave_f*.gd`, tier-1 | **28/28** ✓ |
| `tests/game/test_load_save.py` (7) | `test_session_save.gd`, `test_session_save_extended.gd` | **7/7** ✓ |
| `tests/gui/**` (~30 modules) | — | **deferred** |

**Current GUT total:** run `./godot/run_tests.sh` — **239** tests (M7 tiers T1b–T1p, settler component, gameplay loop, demo/tier-1 integration).

**DLC scaffolding (pre-parity):** see [`DLC_VISION.md`](DLC_VISION.md) and [`PORT_CHECKLIST_DLC.md`](PORT_CHECKLIST_DLC.md).

---

## Appendix D — Parity scenarios (dual-run harness)

| Scenario | Legacy + Godot | Golden (`golden/*.godot.json`) |
|----------|----------------|--------------------------------|
| `wood.json` | `./development/godot/parity/run_pair.sh` | ✓ |
| `warehouse_collector.json` | same | ✓ |
| `farm_crop.json` | same | ✓ |
| `snapshot_roundtrip.json` | same | ✓ |
| `stonemason.json` | same | ✓ |
| `tier1_starter.json` | same | ✓ |
| `brickyard.json` | same | ✓ |
| `toolmaker.json` | same | ✓ |
| `snapshot_mid_production.json` | same | ✓ |
| `brickyard_development.json` | same | ✓ |

Docs: [`development/godot/parity/README.md`](../development/godot/parity/README.md). CI: workflow job **`parity-golden`**. Optional local: `./development/godot/sync.sh --parity`.

---

## Recommended next 10 tasks (ordered)

1. **Idle/work gfx swap** from producer state + atlas pipeline beyond stem slice.  
2. **SQLite save load** — full settlement/inventory mapping beyond building subset (PoC import UI done on desktop).  
3. **Collector pathfinding E3** (roads / walk-home).  
4. **FieldUtilization** + automated farm fields.  
5. **Gfx atlas pipeline** — sqlite atlas import beyond 5-building slice.  
6. **SP session loop** (ship → found settlement).  
7. **GUI pytest port** (batch ingame tabs).  
8. **Game clock** edge cases (`test_timer.py` remainder).  
9. **Units YAML export** expansion.  
10. **MP / scenarios** (XL deferred).

---

*Last updated: Next-10 batch — ground map `modify_area`, LAND/COAST terrain, warehouse storage collectors, pathfinder E2, snapshot v3, MessageBus, wave F4 GUT (106 tests).*
