# GUI port strategy (Godot re-spec)

Legacy Unknown Horizons ingame UI is **PyChan + FIFE**. The Godot port **does not** translate XML widgets line-for-line. Instead we reimplement **behaviors** covered by `legacy/tests/gui/**` using Godot **Control** nodes, **commands**, and **MessageBus**.

## Waves

| Wave | Goal | Legacy pytest themes | Godot anchors |
|------|------|----------------------|---------------|
| **GUI-1** | Playable HUD shell | `test_hud.py` (partial) | [`game_hud.gd`](../scripts/view/game_hud.gd) inspection tabs, [`warehouse_tab.gd`](../scripts/view/warehouse_tab.gd), [`logbook_hud_panel.gd`](../scripts/view/logbook_hud_panel.gd) |
| **GUI-2** | Warehouse + production | `test_warehouse.py` | [`inventory_panel.gd`](../scripts/view/inventory_panel.gd), [`production_overview_panel.gd`](../scripts/view/production_overview_panel.gd) |
| **GUI-3** | Build + log | `test_build.py` (partial), `test_logbook.py` | [`build_palette_panel.gd`](../scripts/view/build_palette_panel.gd), logbook via `MessageBus.logbook_entry` |
| **GUI-4+** | Ships, trade, diplomacy | `test_traderoute.py`, `test_diplomacy.py`, … | Blocked on sim (ships, trade routes, MP) |

Detailed per-test rows: [`PORT_CHECKLIST_GUI.md`](../PORT_CHECKLIST_GUI.md).

## Rules

1. **Sim authority:** HUD reads `GameSession` / `Building` / `Inventory`; writes go through `CommandManager` only.
2. **Tier B imports:** Layout inspiration from [godot-port](EXTERNAL_GODOT_PORT.md); no upstream production/storage components.
3. **Done means:** settlement demo playable with inspect + transfer + log without dev-only panels.

## Status (2026-10)

- **GUI-1:** inspection `TabContainer`, multi-resource transfer buttons, logbook panel — **landed**
- **GUI-2:** dynamic extra resources on settlement/building panels — **partial**
- **GUI-3:** build palette icons (gfx); logbook wired for collector transfers — **partial**
