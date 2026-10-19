# Godot port — GUI test checklist (detailed)

Tick `[ ]` → `[x]`. These mirror **FIFE + PyChan** tests under `tests/gui/`. Godot re-spec: **GUT scene tests** or manual QA — do not port XML literally.

**Difficulty:** ★☆☆☆☆ (S) … ★★★★★ (XL) · see [PORT_CHECKLIST.md](PORT_CHECKLIST.md#legend).

**Blocked by (typical):** sim commands, map view, ingame HUD shell, selection pipeline.

**Strategy doc:** [`docs/GUI_PORT_STRATEGY.md`](docs/GUI_PORT_STRATEGY.md) (waves GUI-1…4).

---

## Ingame (`tests/gui/ingame/`)

### `test_build.py` — ★★★★☆ (L)

- [ ] **`test_found_settlement`** — Ship + warehouse placement, found settlement flow.  
  - **Python widgets:** build menu, settlement founding.  
  - **Godot:** `BuildCommand` + `new_settlement()` parity; scene: ship selected → build warehouse → assert settlement exists.  
  - **Sim tests first:** `tests/game/utils.py` `new_settlement`.

### `test_hud.py` — ★★★☆☆ (M)

- [x] **`test_hud`** — Top bar resources, speed controls visible. *(partial)*  
  - **Godot:** [`game_hud.gd`](scripts/view/game_hud.gd) header + inspection tabs + logbook; speed controls still open.

### `test_selection.py` — ★★★★☆ (L)

- [ ] **`test_select_ship`** — Click ship, selection outline/tab.  
- [ ] **`test_selectmultitab`** — Multi-selection tab behavior.  
- [ ] **`test_selection_groups`** — Group selection shortcuts.  
  - **Godot:** `SelectionTool` state machine; sync from sim `selected_instances` set.

### `test_warehouse.py` — ★★★★☆ (L)

- [x] **`test_production_overview`** — Warehouse production overview widget. *(partial)*  
  - **Godot:** [`production_overview_panel.gd`](scripts/view/production_overview_panel.gd) per-line state + producing **%** progress, [`warehouse_tab.gd`](scripts/view/warehouse_tab.gd) quick + custom transfer row, [`inventory_panel.gd`](scripts/view/inventory_panel.gd) icon grid for primary/extra resources.

### `test_traderoute.py` — ★★★★★ (XL)

- [ ] **`test_traderoute`** — Route config UI + apply to ship.  
  - **Blocked by:** `traderoute.py` sim port, ship units.  
  - **Widgets:** `routeconfig`, ship overview.

### `test_logbook.py` — ★★★☆☆ (M)

- [x] **`test_logbook`** — Message log scroll + entries. *(partial)*  
- [ ] **`test_logbook_statistics`** — Stats section in logbook.  
  - **Godot:** `MessageBus.logbook_entry` → [`logbook_hud_panel.gd`](scripts/view/logbook_hud_panel.gd).

### `test_dialogs.py` — ★★★☆☆ (M)

- [ ] **`test_change_name`** — Rename settlement/building dialog.  
- [ ] **`test_change_name_empty_not_allowed`** — Validation.  
- [ ] **`test_chat`** — Multiplayer chat dialog *(MP optional)*.

### `test_diplomacy.py` — ★★★☆☆ (M)

- [ ] **`test_diplomacy`** — Diplomacy window with other players.  
  - **Blocked by:** `diplomacy.py`, `command/diplomacy.py`.

### `test_keys.py` — ★★☆☆☆ (S)

- [ ] **`test_ticket_1342`** — Hotkey binding regression.  
  - **Godot:** InputMap + `gui/keylisteners` behavior parity.

### `test_windows.py` — ★★★☆☆ (M)

- [ ] **`test_settings_dialog_crash`** — Settings open/close without crash.  
- [ ] **`test_settings_dialog_crash2`** — Second settings edge case.  
  - **Godot:** Modal `AcceptDialog` / settings scene; GUT `InputSender`.

### `test_boatbuilder.py` — ★★★★★ (XL)

Queue / single-use production UI (8 ticket tests):

- [ ] `test_ticket_1224` — Queue display basics.  
- [ ] `test_ticket_1294` — Queue ordering.  
- [ ] `test_ticket_1830` — Production pause in UI.  
- [ ] `test_remove_from_queue` — Remove queued unit.  
- [ ] `test_cancel_ticket_1424` — Cancel in-progress.  
- [ ] `test_save_load_ticket_1421` — Queue persists save/load.  
- [ ] `test_ticket_1513` / `test_ticket_1514` — Additional queue edge cases.  
  - **Blocked by:** `QueueProducer`, save/load, boat builder building type.

### `test_bugs.py` — ★★★★★ (XL)

Regression suite (16 tests) — port **only when** related sim feature exists:

- [ ] `test_ticket_1352` … `test_ticket_2500` *(see file for steps)*  
- [ ] `test_pavilion_build_crash_built_via_settler_related_tab` — Settler tab build path.  
  - **Approach:** One ticket → one GUT regression; link GitHub issue in test comment.

### `test_generated.py` — ★★★★☆ (L)

- [ ] **`test_build_a_settlement`** — Automated settlement build scenario.  
- [ ] **`test_buildingtool`** — Building tool placement smoke test.  
  - **Godot:** Highest-value smoke once `buildingtool` exists.

---

## Main menu (`tests/gui/menu/`)

### `test_mainmenu.py` — ★★★☆☆ (M)

- [ ] Main menu loads, buttons navigate.  
  - **Godot scene:** `scenes/menu/main_menu.tscn`.

### `test_singleplayermenu.py` — ★★★☆☆ (M)

- [ ] Map list, start game, player setup.  
  - **Blocked by:** map load, session start.

### `test_saveload.py` — ★★★★☆ (L)

- [ ] Savegame list, load, continue.  
  - **Blocked by:** save format port.

### `test_multiplayer.py` — ★★★★★ (XL)

- [ ] MP lobby, connect, start.  
  - **Blocked by:** network stack.

---

## Other GUI tests

| File | Difficulty | Notes |
|------|------------|--------|
| `tests/gui/test_editor.py` | ★★★★★ (XL) | Map editor; defer. |
| `tests/gui/test_unicode.py` | ★★☆☆☆ (S) | Font/glyph smoke in Godot Theme. |
| `tests/gui/test_internal.py` | ★★★☆☆ (M) | PyChan internals — replace with Control tests. |
| `tests/gui/test_helper_find.py` | ★★☆☆☆ (S) | Test helpers — rewrite for Godot node paths. |
| `tests/gui/test_mousetools.py` | ★★★★☆ (L) | Cross-tool integration. |
| `tests/gui/scenarios/test_simple.py` | ★★★★☆ (L) | Scenario UI smoke. |
| `tests/gui/scenarios/test_tutorial.py` | ★★★★★ (XL) | Full tutorial — scenario engine first. |

---

## Godot widget mapping (reference)

| PyChan / UH widget (examples) | Godot target |
|-------------------------------|--------------|
| `horizons/gui/widgets/inventory.py` | `GridContainer` + slot `Panel` |
| `horizons/gui/widgets/minimap.py` | `SubViewport` + orthographic camera |
| `horizons/gui/widgets/messagewidget.py` | Log + `MessageBus` subscription |
| `horizons/gui/tabs/*` | `TabContainer` scenes per building type |
| `horizons/gui/mousetools/buildingtool.py` | Tool state + command queue |

---

*Complement to [PORT_CHECKLIST.md](PORT_CHECKLIST.md). Last updated after scheduler/storage/shapes GUT expansion.*
