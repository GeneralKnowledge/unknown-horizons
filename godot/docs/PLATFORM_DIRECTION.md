# Platform direction (decision record)

This document compares three paths for the Godot port. **No single choice is locked here**; it records tradeoffs after Phase 1 demo work.

## Option A — Faithful browser port

- **Hosting:** Static files (`build/web`), JSON saves in `user://` per origin.
- **Strengths:** Lowest ops cost; shareable URL; matches current export pipeline.
- **Costs:** No SQLite in browser; multiplayer needs a separate command API later.
- **Gates:** Phase 1 browser demo checklist green; save validation UX; map/camera/build loop stable.

## Option B — Standalone inspired game

- **Hosting:** Desktop builds primary; relaxed save parity with legacy Python.
- **Strengths:** Faster iteration on rules and content; full filesystem and SQLite tooling.
- **Costs:** Divergence from legacy regression tests; separate web story optional.
- **Gates:** Clear save format policy in `SAVE_FORMAT.md`; parity harness scope agreed.

## Option C — Persistent multiplayer

- **Hosting:** Authoritative server, command log, anti-cheat, session model.
- **Strengths:** Shared worlds, competitive/co-op play.
- **Costs:** Largest engineering surface; not compatible with static-only Phase 1.
- **Gates:** Deterministic sim tick + command serialization proven; Phase 3 settlement loop tests.

## Current default trajectory

Until explicitly changed, development favors **Option A** for public demos (JSON saves, static host) while keeping **desktop dev tools** (SQLite diagnostics, parity scripts) on `master`.
