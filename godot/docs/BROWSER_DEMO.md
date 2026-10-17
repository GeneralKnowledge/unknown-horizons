# Browser demo (Phase 1)

What the **Web** export of `scenes/poc_main.tscn` is meant to demonstrate, and what is intentionally out of scope.

## Works in the browser

| Feature | Notes |
|---------|--------|
| Start menu | New game, Continue (`user://poc_snapshot.json`), Import save |
| Default map | `development` island from `resources/demo/demo_config.json` |
| Camera | Middle-drag pan, mouse wheel zoom, fit-to-island on load |
| Build palette | Tier tabs from exported `build_menu.json`; ghost valid/invalid tint |
| Production HUD | Settlement + selected building inventories; production strip when a building is selected |
| JSON saves | Save/Load in `user://`, Download save, Import save (FileDialog + same validation as desktop) |
| Audio | First user interaction may play a sample sound (autoplay policy) |

## Does not work (by design)

| Feature | Why |
|---------|-----|
| Legacy SQLite import | No filesystem SQLite in WASM; use JSON saves |
| Full legacy save parity | Placement rules and scheduler restore differ; see `SAVE_FORMAT.md` |
| Dev map hotkeys | Start menu replaces casual use of keyboard map switches |

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

Bundled scenario JSON (manual QA / future scripted demos):

- `resources/demo/starter_island_scenario.json` — tier-2 clay → brickyard on the development map
- `resources/demo/starter_tier1_scenario.json` — tier-1 lumberjack, hunter, and fisher on the test island; **place lumberjack before hunter/fisher** (warehouse collector). Covered by `test_starter_tier1_scenario.gd` and parity scenario `tier1_starter`.
