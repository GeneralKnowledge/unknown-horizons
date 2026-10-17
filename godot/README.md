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

## Prerequisites

- Godot **4.3+** (headless binary for CI)
- Python 3 + PyYAML (to refresh exports)

## Refresh content exports

From repo root:

```bash
python3 development/godot/export_content.py
```

This writes `scripts/autoload/game_constants.gd` and `resources/exported/buildings.json`.

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

- **Space**: add 2 trees to the lumberjack (starts production)
- **Enter**: remove one board from storage (debug)

## Adding the next pytest as a GUT test

1. Find the Python test under `tests/unittests/` or `tests/game/`.
2. Add a matching `tests/unit/` or `tests/integration/*.gd` file extending `GutTest`.
3. Instantiate `GameSession` / plain sim classes instead of FIFE session mocks.
4. Run `./run_tests.sh`.

## Port roadmap

See **[PORT_CHECKLIST.md](PORT_CHECKLIST.md)** for sim/world tasks and **[PORT_CHECKLIST_GUI.md](PORT_CHECKLIST_GUI.md)** for per-GUI-test breakdown (widgets, blockers, Godot approach).
