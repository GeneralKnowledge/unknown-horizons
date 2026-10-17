# Unknown Horizons — Godot port (PoC)

Experimental Godot 4 reimplementation focused on **headless simulation parity** with the Python game, plus a minimal playable lumberjack slice.

## Layout

| Path | Role |
|------|------|
| `scripts/sim/` | Scheduler, storage, production, session (no `Node2D` — GUT-friendly) |
| `scripts/view/` | Thin presentation (`poc_main.gd`) |
| `resources/content` | Symlink to repo `content/` |
| `resources/exported/` | JSON + generated constants from Python export |
| `tests/` | GUT unit + integration tests |
| `docs/PROJECT_ROADMAP.md` | Audit, milestones, browser blockers |

## Prerequisites

- Godot **4.3+** (headless binary for CI)
- Python 3 + PyYAML (to refresh exports)

## Refresh content exports

From repo root (recommended — matches CI):

```bash
./development/godot/sync.sh --skip-tests   # export content + gfx + validate + matrix report
./development/godot/sync.sh                # same, then GUT
```

Or manually:

```bash
python3 development/godot/export_content.py
python3 development/godot/export_gfx.py
python3 development/godot/validate_content.py
```

See [docs/SCAFFOLDING.md](docs/SCAFFOLDING.md) for test recipes, `SaveLoader`, and component factories.

## Run tests (headless)

```bash
./godot/run_tests.sh
```

Or:

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

## Run PoC scene

Open `godot/project.godot` in the editor and run `scenes/poc_main.tscn`, or:

```bash
godot --path godot scenes/poc_main.tscn
```

### Controls

- **Build palette** buttons or keys **1** (lumberjack), **2** (tree), **3** / **T** (tear)
- **Left click** — place building (when build mode active) or pick building
- **Right click** — select building under cursor
- **Ui select** (Space) — toggle build mode
- **Save / Load / Download / Import** — JSON snapshot (see HUD)

Gameplay loop: place **lumberjackcamp**, place **tree** tiles nearby, wait for **boards** in building storage (sim-driven).

Dev builds show a **+2 TREES** debug button; release/web builds do not.

## Browser build

```bash
./godot/export_web.sh
```

See [docs/WEB_DEPLOYMENT.md](docs/WEB_DEPLOYMENT.md).

## Adding the next pytest as a GUT test

1. Find the Python test under `tests/unittests/` or `tests/game/`.
2. Add a matching `tests/unit/` or `tests/integration/*.gd` file extending `GutTest`.
3. Instantiate `GameSession` / plain sim classes instead of FIFE session mocks.
4. Run `./run_tests.sh`.

## Port roadmap

See **[PORT_CHECKLIST.md](PORT_CHECKLIST.md)** for sim/world tasks and **[PORT_CHECKLIST_GUI.md](PORT_CHECKLIST_GUI.md)** for per-GUI-test breakdown (widgets, blockers, Godot approach).
