# Building gfx export (legacy → Godot)

Godot loads building sprites from `godot/resources/gfx/<stem>/`:

- `idle.png`, `working.png` — copied from legacy `content/gfx`
- `sprite_manifest.json` — metadata for [`BuildingVisualRegistry`](../../godot/scripts/view/building_visual_registry.gd)

## Commands

From repository root (after `export_content.py`):

```bash
# Export all building stems in buildings.json (recommended; used by sync.sh)
python3 development/godot/export_gfx.py --auto

# Subset
python3 development/godot/export_gfx.py --auto --stems lumberjackcamp,farm,tree

# Manual slice only (legacy hard-coded map in export_gfx.py)
python3 development/godot/export_gfx.py
```

Discovery report: `godot/resources/gfx/export_report.json` (actionset, paths, errors).

## How discovery works

[`gfx_discovery.py`](gfx_discovery.py):

1. Load building YAML from `legacy/content/objects/buildings/<stem>.yaml` or `buildings/fields/<stem>.yaml`.
2. Pick a tier actionset (`as_*`) from `actionsets` (prefers `TIER.SAILORS`, then pioneers, citizens, …).
3. Locate `as_*` under `legacy/content/gfx/**`.
4. **Idle:** `idle` / `idle_full` / first action with a **135°** frame (`0.png` or `000.png`).
5. **Working:** overlay hints from `InventoryOverlayComponent`, else first non-idle action (e.g. `logs_1`, `bricks_01`, `work`), else idle.

Manual overrides in `LEGACY_BUILDING_GFX` inside [`export_gfx.py`](export_gfx.py) win over auto-discovery (use for better working frames).

## Parity / sim

This pipeline is **view-only**. It does not change `GameConstants`, production rules, or GUT. After large exports, run `./godot/export_web.sh` if you rely on web CI.

## Units, terrain, ships (not yet)

Legacy units use the same actionset tree under `content/gfx/units/`. A future `export_unit_gfx.py` can mirror `gfx_discovery.py` using `content/objects/units/*.yaml`. Terrain and ships are similar; keep them out of `scripts/sim/`.

## godot-port Tier A alternative

Pre-cut `Buildings2` PNG/`.tres` from [godot-port](https://github.com/unknown-horizons/godot-port) can supplement or replace slices for demos; **this exporter stays tied to `legacy/content`** so YAML/actionset changes remain the source of truth. See [`godot/docs/EXTERNAL_GODOT_PORT.md`](../../godot/docs/EXTERNAL_GODOT_PORT.md) tiers A/B/C.
