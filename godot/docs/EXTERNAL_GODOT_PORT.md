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

## Import allowlist

- UI icons, theme references (view only)
- Interaction **patterns** (context stack → our `ViewContextManager`)
- Map manifest **JSON shape** (`maps_manifest.json`, `user://maps`)
- Building **sprites/scenes** in `scripts/view/` only

## Import denylist

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
