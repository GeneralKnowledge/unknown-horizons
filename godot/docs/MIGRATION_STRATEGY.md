# Godot migration strategy (draft)

Unknown Horizons keeps the **Python + FIFE** game shippable while the **Godot 4** project matures under `godot/`.

## Dual-run (current phase)

- **Source of truth for balance/content:** `content/` and `horizons/` (unchanged workflow for contributors).
- **Godot consumes content** via `development/godot/export_content.py` (constants, buildings JSON, production line id map).
- **Correctness:** port pytest scenarios to GUT under `godot/tests/`; aim for behavioral parity on sim logic before replacing UI.
- **Release:** no Godot binary in official downloads until a agreed milestone (e.g. settlement loop + save/load + core UI).

## Cutover criteria (proposal)

1. GUT coverage for all `tests/game/` integration tests (or documented exceptions).
2. Headless save/load round-trip for a standard map.
3. Single-player session playable without Python installed (menu → build → produce → save).
4. Performance equal or better on reference hardware for a large map.

## Principles

- **Sim/view split:** rules in `scripts/sim/`; scenes only render and enqueue commands.
- **Commands:** same conceptual operations as `horizons/command/` for future MP parity.
- **Do not port PyChan XML literally;** reimplement UX in Godot Control nodes.

See [PORT_CHECKLIST.md](../PORT_CHECKLIST.md) for tickable tasks.
