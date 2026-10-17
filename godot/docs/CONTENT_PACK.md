# Content pack manifest (view layer)

Simulation building and resource **ids never change**. Packs reskin labels, optional gfx roots, sounds, and UI theme ids.

## Layout

```
resources/dlc/<pack_id>/
  manifest.json      # required
  ui_labels.json     # optional building display names
  sounds.json        # optional legacy audio key → res:// path
  gfx/               # optional sprites (see gfx_root)
```

## `manifest.json` fields

| Field | Required | Purpose |
|-------|----------|---------|
| `pack_id` | yes | Directory name and `active_theme.json` reference |
| `display_name` | yes | HUD suffix via autoload `ContentTheme` |
| `gfx_root` | no | Repo-relative or `res://` path to pack gfx |
| `player_accent_color` | no | Hex color for future HUD theming |
| `sounds_manifest` | no | Filename under pack dir (default `sounds.json`) |
| `ui_theme` | no | Future Godot `Theme` resource id |
| `buildings` | DLC only | Id range + stem list for DLC loaders |

Activate a pack in `resources/exported/active_theme.json`:

```json
{
  "pack_id": "northern_company",
  "hud": {
    "accent_color": "#4a7c9e",
    "status_ok_color": "#d8f0e8",
    "status_error_color": "#ff6666"
  }
}
```

Copy from `active_theme.northern_company.example.json`. HUD colors override manifest `player_accent_color` when set.

### `ui_labels.json` (schema v1)

```json
{
  "schema_version": 1,
  "labels": {
    "lumberjackcamp": "Timber Camp (NC)"
  }
}
```

Flat stem → string maps (no `schema_version`) remain supported for older packs.

## Gfx lookup order

[`BuildingVisualRegistry`](../scripts/view/building_visual_registry.gd) resolves `sprite_manifest.json` per stem:

1. `{manifest.gfx_root}/{stem}/sprite_manifest.json` when a pack is active
2. `res://resources/gfx/{stem}/sprite_manifest.json` (default export)

Pack-level `gfx/sprite_manifest.json` supplies optional `building_tints` for stem modulate.

## Northern Company reference pack

See `resources/dlc/northern_company/manifest.json` — labels, gfx root, tints, and sound override for lumberjack sample.
