# Godot migration strategy (draft)

Unknown Horizons keeps the **Python + FIFE** game shippable while the **Godot 4** project matures under `godot/`.

## Dual-run (current phase)

- **Source of truth for balance/content:** `legacy/content/` and `legacy/horizons/` (unchanged workflow for contributors editing YAML).
- **Godot consumes content** via [`development/godot/export_all.sh`](../../development/godot/export_all.sh) / [`EXPORT_PIPELINE.md`](../../development/godot/EXPORT_PIPELINE.md) (constants, buildings JSON, gfx, maps, unit gfx).
- **Correctness:** port pytest scenarios to GUT under `godot/tests/`; aim for behavioral parity on sim logic before replacing UI.
- **Release:** no Godot binary in official downloads until a agreed milestone (e.g. settlement loop + save/load + core UI).

## Cutover criteria (proposal)

1. GUT coverage for all `tests/game/` integration tests (or documented exceptions).
2. Headless save/load round-trip for a standard map.
3. Single-player session playable without Python installed (menu → build → produce → save).
4. Performance equal or better on reference hardware for a large map.
5. **Legacy save compatibility:** representative **original-game saves** load in Godot; automated fixture tests prove inventories/buildings/state match expectations (see [PROJECT_ROADMAP.md — Future ideas](PROJECT_ROADMAP.md#future-ideas)).
6. **Cross-version confidence (before moving on):** ability to **transition smoothly** from Python to Godot on the same save; stretch goal — **play across versions** (you on Python, another player on Godot) on a shared world via a common command/sync layer.

Until (5) is largely green, treat Godot as a parallel client, not a replacement.

## Legacy saves and cross-version play (future gate)

| Step | What |
|------|------|
| Export path | Keep using `content/` + pytest/GUT parity for *rules*; saves prove *integration* |
| Load Python saves in Godot | Expand `SqliteSaveLoader` beyond building subset; map + units + session metadata |
| Test harness | [`LEGACY_SAVE_FIXTURES.md`](LEGACY_SAVE_FIXTURES.md) + `sqlite_fixture_matrix.py`; CI matrix over in-repo `.sqlite` files |
| Player workflow | Document save-in-Python → load-in-Godot for early adopters |
| Mixed clients | Shared authoritative sim (server or host); Python and Godot as peers—validates command parity under real latency |

This is listed in [PROJECT_ROADMAP.md](PROJECT_ROADMAP.md) as milestone **M7** / future ideas—not implemented in the PoC phase.

**Current PoC stepping stones (2026-10):** JSON snapshot v3 with GUT + `snapshot_roundtrip` parity; desktop **partial** legacy `.sqlite` import (buildings, storage/units subset) with PoC FileDialog UI and CI fixture matrix; no cross-client sync or full savegamerev fidelity yet.

## Principles

- **Sim/view split:** rules in `scripts/sim/`; scenes only render and enqueue commands.
- **Commands:** same conceptual operations as `horizons/command/` for future MP parity.
- **Do not port PyChan XML literally;** reimplement UX in Godot Control nodes.

See [PORT_CHECKLIST.md](../PORT_CHECKLIST.md) for tickable tasks.
