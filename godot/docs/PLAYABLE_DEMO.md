# Playable settlement demo

Vertical slice objective: **deliver building materials (boards) to the settlement warehouse** on the `development` map.

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

Configuration: `resources/demo/playable_lumber_demo.json` (map, target boards, starting gold/tools).

## Saves

JSON snapshots include optional top-level `demo.playable_lumber` (`completed`, targets). Legacy SQLite import remains **desktop-only** and partial — use JSON for the demo loop.

## Known limitations

- Single guided objective, not a full campaign.
- Not every legacy save field or production detail is persisted (see `docs/SAVE_FORMAT.md`).
- Browser builds cannot import SQLite; save via JSON export/download.
