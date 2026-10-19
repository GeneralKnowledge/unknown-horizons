# Playable settlement demo

Three entry points from the title menu:

| Mode | Config | Purpose |
|------|--------|---------|
| **Settlement demo (short)** | `playable_lumber_demo.json` | 2 steps: lumber → bricks |
| **Northern expedition** | `playable_northern_expedition.json` | 8 steps: food, tools, weaver, DLC smokery/faith |
| **Living village showcase** | `northern_village_showcase.json` | Pre-built village + ~100s sim warmup |

All use the `development` map (warehouse at **30,30**; expedition clay deposit at **33,33**, aligned with parity `brickyard_development`).

Scenario JSON shape: [`DEMO_SCENARIO_FORMAT.md`](DEMO_SCENARIO_FORMAT.md) (`schema_version`, `kind`, shared `placements` / `steps`).

Buildings charge **YAML `buildingcosts`** from settlement stock (gold, boards, tools, …). Founding warehouse remains free.

## Launch

```bash
cd godot
godot4 --path .   # or project export
```

The project shows the **Godot boot splash** for at least 1.5s (`project.godot` → `config/boot_splash/*`) before the title menu.

### Progress demo video (local / marketing)

```bash
chmod +x development/godot/record_progress_demo_video.sh
DISPLAY=:0 ./development/godot/record_progress_demo_video.sh godot/build/progress_demo.mp4
```

Records: Godot splash → title menu → automated start of the settlement demo → sim running (requires `ffmpeg`, `xdotool`, and a visible `DISPLAY`).

Choose **Start settlement demo (short)**, **Northern expedition (full demo)**, or **Living village showcase**.

## Controls

| Input | Action |
|--------|--------|
| **B** | Build mode |
| **S** | Select mode |
| **T** | Tear mode |
| Middle-drag | Pan map |
| Mouse wheel | Zoom |
| Build palette | Place lumberjack camp and trees |
| HUD **Pause simulation** | Freeze sim tick (UI stays interactive) |
| **Save JSON** / **Load JSON** | Desktop `user://poc_snapshot.json`; browser uses download/import |

## Flow

**Step 1 — lumber**

1. Place a **lumberjack camp** inside the settlement build area (green ghost = valid; red = invalid or insufficient resources).
2. Plant **trees** near the camp.
3. Let the simulation run; collectors move **boards** into the settlement warehouse until the objective panel target is met.

**Step 2 — bricks**

4. Build a **clay pit** on the clay deposit (spawned near the settlement).
5. Build a **brickyard** inside the build area; wait for **bricks** in the warehouse.
6. When both steps complete, the **success overlay** appears (you can keep playing or save).

Configuration: `resources/demo/playable_lumber_demo.json` (steps, clay deposit spawn, starting stock).

### Screenshots

From repo root:

```bash
./development/godot/capture_demo_storyboard.sh
```

Writes PNGs under `godot/docs/screenshots/storyboard/` (living village wide/lumber/brickyard/DLC/HUD + title menu). Legacy four-beat captures remain in `capture_playable_demo_screenshots.sh`.

### Slice video (automated)

```bash
./development/godot/record_demo_slice_video.sh
```

Uses `scenes/playable_slice.tscn` with `--video-slice=settlement_demo` (no title menu or mouse input): lumber step → clay deposit marker → success overlay, with camera moves driven in `poc_main.gd`.

Living village pan (showcase JSON camera spots):

```bash
godot4 --path godot scenes/playable_slice.tscn --video-slice=living_village
```

## Browser hosting

CI can publish the WASM build to **GitHub Pages** via `.github/workflows/godot-pages.yml` (after enabling Pages for the repo). Local verify: `./godot/export_web.sh` then `development/godot/web_export_smoke.sh`.

## Saves (canonical: JSON v3)

**Use JSON for the demo loop** — desktop writes `user://poc_snapshot.json`; browser uses **Save JSON** (download) and **Load JSON** (file picker). Format: [`SAVE_FORMAT.md`](SAVE_FORMAT.md).

JSON snapshots include optional top-level `demo` progress:

- `demo.playable_lumber` — short two-step demo (`profile`: `short`)
- `demo.playable_northern_expedition` — eight-step expedition (`profile`: `expedition`)

The title menu **Continue JSON save** restores whichever profile was saved.

Legacy `.sqlite` import is **desktop-only**, **partial**, and **frozen** (experiments only) — [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md). Do not rely on sqlite for demo checkpoints.

## Known limitations

- Single guided objective, not a full campaign.
- Not every legacy save field or production detail is persisted (see `docs/SAVE_FORMAT.md`).
- Browser builds cannot import SQLite; save via JSON export/download.
