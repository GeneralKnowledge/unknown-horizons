# Browser demo (Phase 1)

What the **Web** export of `scenes/poc_main.tscn` is meant to demonstrate, and what is intentionally out of scope.

## Works in the browser

| Feature | Notes |
|---------|--------|
| Start menu | **Start settlement demo**, economy showcase, **Continue JSON save** (after HUD save), Import JSON, legacy **`.extract.json`** on web; raw `.sqlite` desktop-only |
| Default map | `development` island from `resources/demo/demo_config.json` |
| Camera | Middle-drag pan, mouse wheel zoom, fit-to-island on load |
| Build palette | Tier tabs from exported `build_menu.json`; ghost valid/invalid tint |
| Production HUD | Settlement + selected building inventories; production strip when a building is selected |
| JSON saves | Same as desktop: Save/Load in `user://`, **Download save**, Import save; stores `demo.playable_lumber` or `demo.playable_northern_expedition` step progress |
| Audio | First user interaction may play a sample sound (autoplay policy) |

## Does not work (by design)

| Feature | Why |
|---------|-----|
| Raw legacy `.sqlite` | Desktop only — use **JSON** for the settlement demo loop |
| Legacy extract bundles | **`.extract.json`** only (start menu + HUD Import) — partial legacy state, not the guided demo |
| Full legacy save parity | Placement rules and scheduler restore differ; see `SAVE_FORMAT.md` |
| Dev map hotkeys | Start menu replaces casual use of keyboard map switches |

## Settlement demo parity (desktop vs browser)

1. **Start settlement demo** or **Northern expedition** — objective panel shows step 1 for the chosen profile.
2. Place lumberjack + trees; **Save JSON** in the HUD.
3. **Return to menu** → **Continue JSON save** must be enabled; continue restores step/progress.
4. On web, also **Download save** and re-import via **Import JSON save** after a refresh (IndexedDB `user://` is per-origin).
5. Complete both steps → success overlay; save again and reload to confirm `demo complete` status line.

Canonical format: [`SAVE_FORMAT.md`](SAVE_FORMAT.md). Legacy import policy: [`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md).

## Quick verify

```bash
./godot/export_web.sh
cd godot/build/web && python3 -m http.server 8080
```

Follow the smoke checklist in [WEB_DEPLOYMENT.md](WEB_DEPLOYMENT.md).

## Demo configuration

Edit `resources/demo/demo_config.json`:

- `default_map_id` — bundled ground id (default `development`)
- `show_start_menu` — set `false` for instant new game (useful for automated runs)
- `default_settlement_x` / `default_settlement_y` — starting warehouse anchor
- `subtitle` — start menu tagline
- `theme_pack_id` — e.g. `northern_company` (applies pack theme on PoC load)
- `showcase_scenario` — resource path for **Play showcase demo** and `shareable_demo.tscn`

## Shareable screenshot

```bash
chmod +x development/godot/capture_shareable_demo.sh
./development/godot/capture_shareable_demo.sh godot/build/shareable_demo.png
```

Opens `scenes/shareable_demo.tscn` (tier-1 buildings, Northern Company theme, title overlay).

Bundled scenario JSON (manual QA / future scripted demos):

- `resources/demo/starter_island_scenario.json` — tier-2 clay → brickyard on the development map
- `resources/demo/starter_tier1_scenario.json` — tier-1 lumberjack, hunter, and fisher on the test island; **place lumberjack before hunter/fisher** (warehouse collector). Covered by `test_starter_tier1_scenario.gd` and parity scenario `tier1_starter`.
