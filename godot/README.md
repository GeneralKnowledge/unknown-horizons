# Unknown Horizons — Godot port

A **Godot 4.3** reimplementation of the Unknown Horizons settlement simulation. The goal is a **browser-playable**, **data-driven** game that keeps the economic settlement loop of the original while allowing future rebranding (art, copy, content packs) without rewriting sim rules.

The **legacy Python + FIFE game** lives in [`../legacy/`](../legacy/); this directory is the active port.

## Design principle

**The simulation decides what is true; the presentation shows it to the player.**

Sim code lives under `scripts/sim/` as headless `RefCounted` types (commands, production, storage, saves). UI and map code under `scripts/view/` issues commands and reads state—it does not fake production or mutate inventories outside dev tools.

## What works today

| Area | Status |
|------|--------|
| Headless sim (scheduler, storage, production, buildability) | Ported + **196** GUT tests |
| Building integration (legacy pytest matrix) | **28/28** building game tests in GUT |
| JSON save/load (schema v3) | PoC HUD + integration tests |
| Playable PoC (`scenes/poc_main.tscn`) | Start menu, **development** map, pan/zoom, tier build palette, lumberjack + tree loop, JSON saves |
| Content pipeline | YAML → `export_content.py` → `resources/exported/` + validation |
| Dual-run parity harness | **10** scenarios vs golden traces (`wood`, warehouse, farm, snapshot, stonemason, tier1_starter) |
| Web export | `./export_web.sh` → static WASM build (see [WEB_DEPLOYMENT.md](docs/WEB_DEPLOYMENT.md)) |
| Theme / reskin demo | `ContentTheme` + Northern Company pack (labels, HUD colors, `gfx/` stems, `.tres` theme) |

## Not in scope yet

- Full original game (ship, found settlement, campaign maps, multiplayer)
- Legacy GUI test suite (~30 pytest modules)
- Complete SQLite save fidelity (subset load on desktop only)
- Automated browser playtesting in CI (manual smoke checklist documented)

## Future ideas (before full cutover)

We should **load real saves from the original Python game** in Godot and prove a smooth handoff (save in legacy → continue in Godot). Ideally, **play across versions** in one world (you on Python, someone on Godot) so command and state parity is real—not only headless traces. That is a deliberate gate documented in [docs/PROJECT_ROADMAP.md](docs/PROJECT_ROADMAP.md#future-ideas) and [docs/MIGRATION_STRATEGY.md](docs/MIGRATION_STRATEGY.md).

## Quick start

**Prerequisites:** Godot **4.3+**, Python 3 + PyYAML.

```bash
# From repo root — export content, validate, run tests (matches CI)
./development/godot/sync.sh

# Play locally
godot --path godot scenes/poc_main.tscn

# Browser build
./godot/export_web.sh
cd godot/build/web && python3 -m http.server 8080
```

### PoC controls

- **Start menu** — New game, Continue (`user://` save), Import save (see [BROWSER_DEMO.md](docs/BROWSER_DEMO.md))
- **Pan / zoom** — middle-drag and mouse wheel on the map
- **Build palette** — tier tabs; or keys **B** / **S** / **T** (build / select / tear)
- **Left click** — place (build mode) or pick building
- **Right click** — select building under cursor
- **Save / Load / Download / Import** — JSON snapshots in the HUD

**Gameplay loop:** place **lumberjackcamp**, place **tree** tiles nearby, wait for **boards** in building storage (sim-driven, not debug cheats).

Debug builds only: **+2 TREES** on the selected building.

## Repository layout

| Path | Role |
|------|------|
| `scripts/sim/` | Simulation (no `Node2D` — GUT-friendly) |
| `scripts/view/` | Map, HUD, input (`poc_main.gd`) |
| `resources/content` | Symlink to `legacy/content/` |
| `resources/exported/` | Generated JSON + constants |
| `tests/` | GUT unit + integration tests |
| `development/godot/` | Python exporters, parity harness, `sync.sh` |

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/PROJECT_ROADMAP.md](docs/PROJECT_ROADMAP.md) | Milestones M0–M6, audit, browser blockers, future living-world/server design |
| [docs/WEB_DEPLOYMENT.md](docs/WEB_DEPLOYMENT.md) | Export templates, hosting, smoke checklist |
| [docs/SAVE_FORMAT.md](docs/SAVE_FORMAT.md) | Snapshot schema v3 |
| [docs/SCAFFOLDING.md](docs/SCAFFOLDING.md) | Test helpers, adding buildings |
| [PORT_CHECKLIST.md](PORT_CHECKLIST.md) | Detailed sim/GUI port tasks |
| [development/godot/parity/README.md](../development/godot/parity/README.md) | Legacy vs Godot trace comparison |

## Refresh exports manually

```bash
python3 development/godot/export_content.py
python3 development/godot/export_gfx.py
python3 development/godot/validate_content.py
```

Optional theme: copy `resources/exported/active_theme.northern_company.example.json` to `active_theme.json` and set `"pack_id": "northern_company"`.

## Adding a ported test

1. Find the Python test under `legacy/tests/unittests/` or `legacy/tests/game/`.
2. Add `tests/unit/` or `tests/integration/*.gd` extending `GutTest`.
3. Use `GameSession` / commands, not FIFE mocks.
4. Run `./godot/run_tests.sh`.

## CI

GitHub Actions (`.github/workflows/godot-tests.yml`): content export, validation, GUT, parity golden traces, headless web export.
