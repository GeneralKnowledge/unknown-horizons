# Godot export pipeline (master)

Single entrypoint to regenerate Godot-facing artifacts from [`legacy/`](../../legacy/).

## Quick start

```bash
chmod +x development/godot/export_all.sh
./development/godot/export_all.sh
```

Full local CI parity (exports + tests):

```bash
./development/godot/sync.sh
```

## Steps and outputs

| Step | Script | Output |
|------|--------|--------|
| 1 | [`export_content.py`](export_content.py) | [`godot/resources/exported/`](../../godot/resources/exported/) — buildings, units, constants, production line ids, PoC menu |
| 2 | [`export_gfx.py --auto`](export_gfx.py) | [`godot/resources/gfx/<stem>/`](../../godot/resources/gfx/) — PNGs + `sprite_manifest.json`; [`export_report.json`](../../godot/resources/gfx/export_report.json) |
| 3 | [`validate_content.py`](validate_content.py) | Exit code 0/1; warnings on collector id gaps |
| 4 | [`export_maps.py`](export_maps.py) | [`godot/resources/maps/ground/*.json`](../../godot/resources/maps/ground/) + updates [`maps_manifest.json`](../../godot/resources/maps/maps_manifest.json) |
| 5 | [`export_unit_gfx.py`](export_unit_gfx.py) | [`godot/resources/gfx/units/<stem>/`](../../godot/resources/gfx/units/) |
| — | [`export_all.sh`](export_all.sh) | [`godot/resources/export_manifest.json`](../../godot/resources/export_manifest.json) |

## Related docs

- Building gfx details: [`GFX_EXPORT.md`](GFX_EXPORT.md)
- Upstream cherry-pick tiers: [`godot/docs/EXTERNAL_GODOT_PORT.md`](../../godot/docs/EXTERNAL_GODOT_PORT.md)
- Legacy save fixtures: [`godot/docs/LEGACY_SAVE_FIXTURES.md`](../../godot/docs/LEGACY_SAVE_FIXTURES.md)
- Migration / M7 saves: [`godot/docs/MIGRATION_STRATEGY.md`](../../godot/docs/MIGRATION_STRATEGY.md)

## Planned extensions (Phase A1)

- `export_grounds.py` — tile metadata from `legacy/content/objects/grounds/`
- `export_build_menu.py` — full tier menus from `gui_buildmenu/` YAML
- `export_audio.py` — OGG paths from YAML ambient components
- Atlas-backed gfx (XL) — `legacy/content/atlas.sql` via `development/generate_atlases.py`

## Parity rules

- Exporters must not embed gameplay rules outside `legacy/content` + `horizons/constants.py`.
- Sim changes require GUT; gfx/maps/audio export are view/world data only.
