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
{ "pack_id": "northern_company" }
```

## Northern Company reference pack

See `resources/dlc/northern_company/manifest.json` — labels, gfx root, and sound override for lumberjack sample.
