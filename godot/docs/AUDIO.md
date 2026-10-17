# Audio (Godot port)

## What exists today

| Layer | Status |
|-------|--------|
| **Export** | `development/godot/export_audio.py` copies legacy ambient OGGs → `godot/resources/audio/exported/` + `manifest.json` |
| **Playback** | Autoload `GameAudioService` (`scripts/view/audio/game_audio_service.gd`) |
| **Buses** | `Ambient` bus (child of `Master`), created at runtime if missing |
| **Game wiring** | No building/unit ambient loops hooked in PoC scenes yet |

## Using GameAudioService

```gdscript
GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")
# or
GameAudioService.play_ambient_res("res://resources/audio/exported/lumberjack.ogg")
```

Missing files log a warning and return `false` — they do not crash.

## Tests

- `godot/tests/unit/test_game_audio_service.gd` — bus + missing file + optional manifest playback

## Not in scope yet

- SFX bus, 3D audio, per-building ambient from YAML at runtime
- Full parity with legacy FIFE sound manager
