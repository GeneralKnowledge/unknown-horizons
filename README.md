# Unknown Horizons (Godot)

Settlement-building simulation for **desktop and browser**, rebuilt in **Godot 4.3** on top of the original Unknown Horizons design and content.

This repository is **Godot-first**: day-to-day development, CI, and releases target the game under [`godot/`](godot/). The original **Python + FIFE** game lives in [`legacy/`](legacy/) for reference, parity testing, and loading classic savegames as the port matures.

## Quick start

**Requirements:** Godot 4.3+, Python 3 + PyYAML (content export).

```bash
# Export content, validate, run 192 GUT tests (same as CI)
./development/godot/sync.sh

# Play the PoC (build, produce, save/load)
godot --path godot scenes/poc_main.tscn

# Browser build
./godot/export_web.sh
cd godot/build/web && python3 -m http.server 8080
```

| Doc | Purpose |
|-----|---------|
| [`godot/README.md`](godot/README.md) | Layout, controls, what works today |
| [`godot/docs/PROJECT_ROADMAP.md`](godot/docs/PROJECT_ROADMAP.md) | Milestones, browser blockers, future cross-version saves |
| [`godot/docs/WEB_DEPLOYMENT.md`](godot/docs/WEB_DEPLOYMENT.md) | Export templates, hosting, smoke checklist |

## Repository layout

| Path | Role |
|------|------|
| [`godot/`](godot/) | **Main game** — sim, UI, tests, web export |
| [`development/godot/`](development/godot/) | Content/gfx exporters, parity harness, `sync.sh` |
| [`legacy/`](legacy/) | Original Python/FIFE game, YAML/SQL content source, pytest suite |

Game data (buildings, resources, maps) is authored under **`legacy/content/`** and exported into `godot/resources/exported/` — do not maintain a second copy.

## Status (summary)

- **195** headless GUT tests; **10** parity scenarios vs golden traces (CI `parity-golden` job)
- Playable slice: lumberjack / tree / production / JSON save-load
- Reproducible **web export** (`./godot/export_web.sh`)
- **Legacy game:** run from `legacy/` — see [`legacy/README.md`](legacy/README.md)
- **Cross-version goal:** load original saves in Godot and eventually play across Python + Godot clients — [`godot/docs/PROJECT_ROADMAP.md#future-ideas`](godot/docs/PROJECT_ROADMAP.md#future-ideas)

## CI

[`.github/workflows/godot-tests.yml`](.github/workflows/godot-tests.yml) — content validation, GUT, parity golden, web export.

## Original game & license

_Unknown Horizons_ is a 2D settlement/economy simulation (GPL v2). Art, audio, and legal notices: [`legacy/doc/`](legacy/doc/). Community links and upstream history are noted in [`legacy/README.md`](legacy/README.md).
