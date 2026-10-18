# Godot migration strategy (draft)

Unknown Horizons development is **Godot-first**: the playable product is under `godot/` (PoC demo, JSON saves, web export). The **Python + FIFE** tree in `legacy/` remains the **content authoring** source and an **archived reference prototype**—not the shipping client.

## Dual-run (content only)

- **Source of truth for balance/content:** `legacy/content/` and `legacy/horizons/` (unchanged workflow for contributors editing YAML).
- **Godot consumes content** via [`development/godot/export_all.sh`](../../development/godot/export_all.sh) / [`EXPORT_PIPELINE.md`](../../development/godot/EXPORT_PIPELINE.md) (constants, buildings JSON, gfx, maps, unit gfx).
- **Correctness:** port pytest scenarios to GUT under `godot/tests/`; Godot-only parity goldens and integration tests—**no requirement** to keep the legacy client green for every change.
- **Release:** Godot web/desktop demo and JSON saves; legacy FIFE build is optional for historians.

## Cutover criteria (Godot-first)

Primary criteria for treating the Godot port as the **main** Unknown Horizons experience:

1. GUT coverage for ported `tests/game/` integration behavior (or documented exceptions).
2. Headless **JSON v3** save/load round-trip for a standard map ([`SAVE_FORMAT.md`](SAVE_FORMAT.md)).
3. **Playable demo** loop (menu → build → produce → save) without Python installed.
4. **Parity goldens** and scenario harness green on Godot (legacy Python optional for local dev).
5. **Web export** reproducible via `./godot/export_web.sh` with documented browser save workflow.

**Not required** for Godot-first cutover (frozen / archived):

- Legacy `.sqlite` full fidelity or Python → Godot → Python round-trip ([`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md)).
- Cross-version session (mixed Python + Godot clients) or reverse sqlite export.
- Running the parallel FIFE client as a release gate.

## Legacy import (experimental, not a gate)

| Topic | Policy |
|------|--------|
| Canonical saves | **JSON v3** (+ web upload/download) |
| Desktop `.sqlite` | Partial import for manual experiments; `partial: true` expected |
| Tests | Fixture matrix + T1l tick goldens = **regression guards** only |
| Detail | [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md), historical notes in [`M7_LEGACY_SAVE.md`](M7_LEGACY_SAVE.md) |

**Current PoC (2026-10):** JSON snapshot v3 with GUT + `snapshot_roundtrip` parity; desktop partial legacy import with PoC FileDialog and CI fixture matrix; no cross-client sync.

## Principles

- **Sim/view split:** rules in `scripts/sim/`; scenes only render and enqueue commands.
- **Commands:** same conceptual operations as `horizons/command/` for future MP parity.
- **Do not port PyChan XML literally;** reimplement UX in Godot Control nodes.

See [PORT_CHECKLIST.md](../PORT_CHECKLIST.md) for tickable tasks and [PROJECT_ROADMAP.md](PROJECT_ROADMAP.md) for **M8** next work.
