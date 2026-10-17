# Unknown Horizons — Godot port

**Play the prototype:** a settlement-building vertical slice driven by the real Unknown Horizons economy simulation—not a UI mock.

```bash
# From repo root (once): export content
python3 development/godot/export_content.py
python3 development/godot/export_gfx.py --auto
python3 development/godot/export_maps.py

# Launch (Godot 4.3+)
godot --path godot
```

Entry point: `scenes/poc_main.tscn` (also `run/main_scene` in `project.godot`).

## What you do in the demo

1. **Title screen** → **Start settlement demo**
2. On the **development** island: place **lumberjack camp** and **trees** (build costs come from settlement stock)
3. Watch **boards** move into the **warehouse** (simulation + collectors—not HUD fakes)
4. Complete step 1 → build **clay pit** on the clay deposit, **brickyard**, deliver **bricks**
5. **Success overlay** → continue, restart, or save JSON and return later

Full controls and saves: [docs/PLAYABLE_DEMO.md](docs/PLAYABLE_DEMO.md)

## Controls (quick reference)

| Key / input | Action |
|-------------|--------|
| **B** / **S** / **T** | Build / Select / Tear |
| Left click | Place building (build mode) or select |
| Middle-drag, wheel | Pan and zoom |
| HUD | Build palette, inventories, objective, save/load |

## Architecture (for contributors)

**The simulation decides what is true; the presentation shows it.**

- `scripts/sim/` — headless rules (commands, production, saves)
- `scripts/view/` — map, HUD, input; issues commands only

Legacy Python + FIFE reference: [`../legacy/`](../legacy/). External Godot reference port: [unknown-horizons/godot-port](https://github.com/unknown-horizons/godot-port) (UX/assets inspiration—not a feature checklist).

## Verification (maintainers)

Existing automation—**do not expand without a concrete regression risk**:

```bash
./godot/run_tests.sh
./development/godot/parity/run_all.sh   # optional; needs exports
./godot/export_web.sh                   # browser build
```

Reported: **204** GUT tests, **10** parity goldens, content validators in CI.

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/PLAYABLE_DEMO.md](docs/PLAYABLE_DEMO.md) | Demo objective, saves, browser |
| [docs/WEB_DEPLOYMENT.md](docs/WEB_DEPLOYMENT.md) | WASM export & Pages |
| [docs/SAVE_FORMAT.md](docs/SAVE_FORMAT.md) | JSON snapshot v3 |
| [docs/PROJECT_ROADMAP.md](docs/PROJECT_ROADMAP.md) | Longer-term milestones |

## Not the full original game

Ships, campaign, multiplayer, and full legacy save parity are out of scope for this prototype. Legacy `.sqlite` import is **partial** and **desktop-only**.
