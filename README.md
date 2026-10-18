# Unknown Horizons (Godot)

Settlement-building simulation for **desktop and browser**, rebuilt in **Godot 4.3** on top of the original Unknown Horizons design and content.

**Godot-first:** play and ship the prototype under [`godot/`](godot/). [`legacy/`](legacy/) remains the YAML/content source and an optional reference client — not the day-to-day product path.

## Play in three commands

```bash
chmod +x development/godot/play_demo.sh
./development/godot/play_demo.sh
# Title menu → Start settlement demo
```

Browser build:

```bash
./godot/export_web.sh && cd godot/build/web && python3 -m http.server 8080
```

Full maintainer sync (export + validate + GUT, same as CI):

```bash
./development/godot/sync.sh
```

## Docs (start here)

| Doc | Purpose |
|-----|---------|
| [**Getting on the road**](godot/docs/GETTING_ON_THE_ROAD.md) | Play locally, host WASM, GitHub Pages |
| [`godot/docs/PLAYABLE_DEMO.md`](godot/docs/PLAYABLE_DEMO.md) | Settlement demo objectives & saves |
| [`godot/README.md`](godot/README.md) | Architecture, controls, verification |
| [`godot/docs/PROJECT_ROADMAP.md`](godot/docs/PROJECT_ROADMAP.md) | Milestones M0–M8 |
| [`godot/docs/WEB_DEPLOYMENT.md`](godot/docs/WEB_DEPLOYMENT.md) | Export templates & smoke checklist |

## Repository layout

| Path | Role |
|------|------|
| [`godot/`](godot/) | **Main game** — sim, HUD, tests, web export |
| [`development/godot/`](development/godot/) | Exporters, parity harness, `play_demo.sh`, `sync.sh` |
| [`legacy/`](legacy/) | Content YAML/SQL, reference Python/FIFE game |

Balance and buildings are authored under **`legacy/content/`** and exported to `godot/resources/exported/` — do not fork content by hand in Godot.

## Status (summary)

- **~246** GUT tests (`./godot/run_tests.sh`; 1 optional pending T1m)
- **14** Godot parity scenarios vs goldens (CI job **`parity-golden`**)
- **Settlement demo:** lumber → bricks, JSON save/load, web download/import
- **Web export:** `./godot/export_web.sh` · optional **GitHub Pages** via [`godot-pages.yml`](.github/workflows/godot-pages.yml)
- Legacy `.sqlite` import: **frozen** experiment — [`godot/docs/LEGACY_IMPORT_FROZEN.md`](godot/docs/LEGACY_IMPORT_FROZEN.md)

## CI

[`.github/workflows/godot-tests.yml`](.github/workflows/godot-tests.yml) — content validation, GUT, parity golden, web export, shareable demo screenshot.

## Original game & license

_Unknown Horizons_ is a 2D settlement/economy simulation (GPL v2). Art, audio, and legal notices: [`legacy/doc/`](legacy/doc/).
