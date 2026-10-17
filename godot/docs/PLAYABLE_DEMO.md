# Playable settlement demo

Two-step vertical slice on the `development` map:

1. **Lumber** — lumberjack camp, trees, deliver **boards** to the warehouse.
2. **Bricks** — clay pit on the bundled deposit, brickyard, deliver **bricks** to the warehouse.

Buildings charge **YAML `buildingcosts`** from settlement stock (gold, boards, tools, …). Founding warehouse remains free.

## Launch

```bash
cd godot
godot4 --path .   # or project export
```

From the title screen choose **Start settlement demo**.

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

1. Place a **lumberjack camp** inside the settlement build area (green ghost = valid).
2. Plant **trees** near the camp.
3. Let the simulation run; collectors move **boards** into the settlement warehouse.
4. When warehouse boards reach the target (see objective panel), the success overlay appears.

Configuration: `resources/demo/playable_lumber_demo.json` (steps, clay deposit spawn, starting stock).

## Browser hosting

CI can publish the WASM build to **GitHub Pages** via `.github/workflows/godot-pages.yml` (after enabling Pages for the repo). Local verify: `./godot/export_web.sh` then `development/godot/web_export_smoke.sh`.

## Saves

JSON snapshots include optional top-level `demo.playable_lumber` (`completed`, targets). Legacy SQLite import remains **desktop-only** and partial — use JSON for the demo loop.

## Known limitations

- Single guided objective, not a full campaign.
- Not every legacy save field or production detail is persisted (see `docs/SAVE_FORMAT.md`).
- Browser builds cannot import SQLite; save via JSON export/download.
