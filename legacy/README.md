# Unknown Horizons — legacy (Python + FIFE)

This directory is the **original Unknown Horizons** implementation: Python 3, [FIFE](https://github.com/fifengine/fifengine), PyChan GUI, and multiplayer via pyenet.

The **active product** in this repository is the Godot port at [`../godot/`](../godot/). This tree remains the:

- **Content source of truth** — `content/` (YAML, SQL, gfx, audio) exported to Godot via [`../development/godot/`](../development/godot/)
- **Reference simulation** — for parity harness and future cross-version save/play ([`../godot/docs/PROJECT_ROADMAP.md`](../godot/docs/PROJECT_ROADMAP.md#future-ideas))
- **Classic playable build** — when you need the full legacy game

## Run the legacy game

From this directory (`legacy/`):

```bash
pip install -r requirements.txt   # plus FIFE/fifechan per upstream wiki
python3 run_uh.py
```

Install/build details match upstream Unknown Horizons wiki (Linux / Windows / macOS). Container workflow: [`development/docker/README.md`](development/docker/README.md) (build with `-f legacy/development/docker/Dockerfile` from repo root).

## Layout

| Path | Role |
|------|------|
| `horizons/` | Game engine (Python) |
| `content/` | Maps, objects, gfx, audio, SQL |
| `tests/` | pytest (unit + game integration) |
| `po/` | Translations |
| `doc/` | Licenses and documentation |
| `run_uh.py` | Launcher |
| `setup.py` | Install / package |

## Tests

```bash
# From legacy/ (requires FIFE and game deps)
pytest tests/unittests/
pytest tests/game/
```

Godot ports of many tests live under [`../godot/tests/`](../godot/tests/).

## Relationship to Godot

```bash
# From repo root — refresh Godot exports from legacy/content
./development/godot/sync.sh
```

Do not edit generated files under `godot/resources/exported/` by hand; change YAML here and re-export.
