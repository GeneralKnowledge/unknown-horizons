# External reference: unknown-horizons/godot-port

Official community Godot rewrite: https://github.com/unknown-horizons/godot-port (`develop`).

This repo **cherry-picks presentation** only. Simulation stays in [`scripts/sim/`](../scripts/sim/) with YAML export and GUT/parity gates.

## Pinned upstream assets

| Item | Location |
|------|----------|
| Commit pin | [`resources/upstream/godot-port/SOURCE_COMMIT.txt`](../resources/upstream/godot-port/SOURCE_COMMIT.txt) |
| Attribution | [`resources/upstream/godot-port/ATTRIBUTION.md`](../resources/upstream/godot-port/ATTRIBUTION.md) |
| Resource icons (32px) | [`resources/upstream/godot-port/icons/resources/32/`](../resources/upstream/godot-port/icons/resources/32/) |

Refresh inventory: `python3 development/godot/inventory_godot_port.py`

## Import tiers (A / B / C)

Use this when deciding what to copy from [godot-port `Assets/`](https://github.com/unknown-horizons/godot-port/tree/develop/Assets). **Parity and saves always use our sim** (`GameConstants`, export JSON, GUT); upstream is for look, layout, and velocity—not a second rules engine.

| Tier | What to import | Where it lands | Parity / CI |
|------|----------------|----------------|-------------|
| **A — Assets (preferred)** | PNGs, `SpriteFrames` (`.tres`), UI `Theme.tres` + style `.tres`, fonts (check license), audio if not already in `legacy/content/` | `resources/upstream/godot-port/` (copy + pin commit in `ATTRIBUTION.md`) | View-only PR: `./development/godot/sync.sh --skip-tests` + PoC smoke + `export_web.sh` if autoloads/resources change. **No GUT required** unless sim touched. |
| **B — Layout (rewire)** | Tab / menu `.tscn` shells, inventory slot scenes, shader cosmetics | `scenes/hud/` or `resources/ui/` with **our** scripts | Same as A; scripts must read `Building` / `Inventory` / `CommandManager`, never `Building2D` or `ResourceConfig` as authority. |
| **C — Forbidden (do not ship)** | Full `Buildings2/*.tscn`, `ProductionLineComponent`, storage/collector component scenes, `WorldDev2D*.tscn` as gameplay map, `BuildingConfig` / `ResourceConfig` IDs, whole `project.godot` | — | Would fork sim truth or require Godot 4.7-only project merge; breaks parity gates. |

### Tier A — detail (high value)

Typical upstream paths (names vary by stem, e.g. `lumberjack` vs export stem `lumberjackcamp`):

- **Building visuals:** `Assets/World/Buildings2/<stem>/` — copy `*.png` + `*.tres` only; wire [`BuildingVisualRegistry`](../scripts/view/building_visual_registry.gd) or a stem alias table. Do **not** copy the sibling `.tscn` if it references production/storage components.
- **UI chrome:** `Assets/UI/Theme/Theme.tres`, `MenuTheme.tres`, icon trees under `Assets/UI/Icons/`.
- **Maps:** adopt **`maps_manifest.json` shape** only; ground truth stays our [`MapLoader`](../scripts/sim/map/map_loader.gd) + legacy/exported ground JSON—not their `WorldDev2D.tscn` sim worlds.

**Long-term art pipeline:** Tier A from godot-port is fastest for demos; **automated legacy export** remains the maintainable source when YAML/actionsets change:

- Master pipeline: [`development/godot/EXPORT_PIPELINE.md`](../../development/godot/EXPORT_PIPELINE.md) + `./development/godot/export_all.sh`.
- [`development/godot/export_gfx.py --auto`](../../development/godot/GFX_EXPORT.md) — discovers actionsets from building YAML → `godot/resources/gfx/<stem>/` (`sprite_manifest.json` + PNGs). Used by `./development/godot/sync.sh`.
- Manual overrides in `export_gfx.py` for better working animations; discovery report in `resources/gfx/export_report.json`.

Re-sync godot-port Tier A only for gaps the legacy exporter misses; avoid maintaining both for the same stem without a pin note in `ATTRIBUTION.md`.

**Demo / tier-1 gfx export (2026-10):** run `python3 development/godot/export_gfx.py --demo --multi-frame` after content export (also invoked from [`export_all.sh`](../../development/godot/export_all.sh)). Curated stems live in `DEMO_GFX_STEMS` inside `export_gfx.py` plus `build_menu.json` tab1.

### Tier B — detail

- **Reference:** `Assets/UI/TabWidgets/` (`InventoryTab`, `ProductionOverviewTab`, building menu tabs).
- **Pattern:** instance or duplicate node tree; bind to [`InventoryPanel`](../scripts/view/inventory_panel.gd), [`production_overview_panel.gd`](../scripts/view/production_overview_panel.gd), [`TransferToSettlementCommand`](../scripts/sim/commands/) etc.
- **Reject:** any upstream script that calls `get_storage_items()`, `ProductionLineComponent`, or mutates storage on the node.

### Tier C — detail

Examples that look tempting but must stay out of merge:

- `Assets/World/Buildings2/lumberjack/lumberjack.tscn` (embeds `ProductionLineComponent`, `SlotStorageComponent`, collectors).
- `Assets/World/Components/ProductionLine/ProductionLineComponent.gd`
- Using `Assets/World/WorldDev2D.tscn` as the PoC map without converting ground into our `Island` format.

If you need behavior from Tier C, port the **rule** into `scripts/sim/` with a GUT or parity scenario first, then add Tier A/B presentation.

## Import allowlist (summary)

Same as **Tier A + B** above:

- UI icons, theme references (view only)
- Interaction **patterns** (context stack → our `ViewContextManager`)
- Map manifest **JSON shape** (`maps_manifest.json`, `user://maps`)
- Building **sprites** (not sim-attached prefabs) under `resources/` + `scripts/view/`

## Import denylist (summary)

Same as **Tier C** above:

- `ProductionLineComponent`, storage/collection components on nodes
- `BuildingConfig` / `Global.ResourceType` as authoritative IDs (use `GameConstants` + export JSON)
- Whole `project.godot` or Godot 4.7-only features without CI re-validation

## Parity gate (every PR)

1. `./development/godot/sync.sh` (or `--skip-tests` for view-only + run targeted GUT)
2. No new `inventory.alter` in `scripts/view/` (except dev debug panel)
3. Sim changes require GUT or parity scenario update
4. Web: `./godot/export_web.sh` when touching resources/autoloads

## Manual smoke (context + icons)

1. PoC loads; settlement/building rows show resource icons
2. Build / select / tear contexts switch via HUD or keys
3. Map picker reloads test stub ground
4. Lumberjack loop still produces boards; save/load works

## Upstream mapping

| godot-port | This repo |
|------------|-----------|
| `GameContextManager` | [`ViewContextManager`](../scripts/view/context/view_context_manager.gd) |
| `ResourceConfig.resource_to_icon` | [`ResourceIconRegistry`](../scripts/view/resource_icon_registry.gd) |
| `maps_manifest.json` | [`resources/maps/maps_manifest.json`](../resources/maps/maps_manifest.json) |
| `InventoryTab` / `ProductionOverviewTab` | [`production_overview_panel.gd`](../scripts/view/production_overview_panel.gd) + inventory panels |

Coordinate large UI efforts via [godot-port issues](https://github.com/unknown-horizons/godot-port/issues) to avoid duplicate work.

## Phase 5 — still sim-first (not from godot-port)

Keep parity-critical work on [`PORT_CHECKLIST.md`](../PORT_CHECKLIST.md):

1. **SQLite save expansion** — [`SqliteSaveLoader`](../scripts/sim/save/sqlite_save_loader.gd)
2. **Collector pathfinding / roads** — sim rules from legacy `horizons/util/pathfinding`
3. **SP session loop** (ship → found settlement)
4. **Parity scenarios** — e.g. `stonemason` golden in `development/godot/parity/`
5. **pytest → GUT** for remaining game tests

Do **not** import godot-port node production/storage components into `scripts/sim/`.

### Upstream inventory CI (optional)

Workflow `upstream-godot-port-inventory` runs `development/godot/inventory_godot_port.py` and checks the pin in `SOURCE_COMMIT.txt` on manual dispatch.
