# DLC port checklist — Northern Company (scaffolding)

Tick when done. **Blocked by parity gate** in [`DLC_VISION.md`](DLC_VISION.md) for full game integration; scaffolding may land earlier.

## Pipeline

- [x] `godot/DLC_VISION.md` parity gates and layout
- [x] `content/dlc/northern_company/manifest.yaml`
- [x] `development/godot/export_content.py` merges DLC packs
- [x] Generated `dlc_constants.gd` + `resources/dlc/*/buildings.json`
- [x] `DlcContentLoader` + `ContentLoader` ID resolution
- [x] `development/godot/export_gfx.py` placeholder atlases
- [x] `BuildingVisualRegistry` + `BuildingView` (idle/work)
- [x] `scenes/dlc_showcase.tscn`
- [ ] Full sqlite atlas import from legacy `content/gfx` (when assets present)
- [ ] MP / faction picker UI

## Northern Company content (IDs 200–204)

| ID | Name | Role |
|----|------|------|
| 200 | `NORTHERN_WAREHOUSE` | Reskin / parallel warehouse stats |
| 201 | `NORTHERN_SMOKERY` | Fish → food chain |
| 202 | `NORTHERN_SIGNAL_TOWER` | Faith producer (pavilion-like) |
| 203 | `NORTHERN_MINT` | Boards → gold (luxury) |
| 204 | `NORTHERN_OUTPOST` | Decorative / zero-radius |

## Tests

| File | Purpose |
|------|---------|
| `tests/dlc/test_northern_company_smoke.gd` | Build + production smoke |
| `tests/dlc/test_northern_scenario.gd` | Short scripted scenario |

**DLC GUT:** included in `./godot/run_tests.sh` via `.gutconfig.json`.
