# Godot port — scaffolding guide

Horizontal infrastructure so feature batches stay small and consistent.

## Sync (local = CI)

From repo root:

```bash
./development/godot/sync.sh          # export content + gfx, matrix report, GUT
./development/godot/sync.sh --skip-tests
```

CI runs `export_content.py`, `export_gfx.py`, `sqlite_save_smoke.py`, then `./godot/run_tests.sh`.

## Integration test recipes

Use [`GameTestSession`](../scripts/sim/test/game_test_session.gd):

| Method | Purpose |
|--------|---------|
| `build_farm(x, y, field_ids)` | Mirror Python `_build_farm` field ring |
| `run_until(building, res_id, min, max_sec)` | Wait for production / finish fallback |
| `snapshot_roundtrip()` | JSON save/load helper |
| `spawn_unit(stem, x, y)` | Units from `units.json` (WildAnimal today) |
| `ToggleActiveCommand` / `TransferToSettlementCommand` | Production toggle + warehouse-style transfer |

## Sim composition

| Piece | Role |
|-------|------|
| [`ComponentFactory`](../scripts/sim/components/component_factory.gd) | Attach Producer, Storage, Collecting, Health, FieldBuilder from export |
| [`CollectorRegistry`](../scripts/sim/units/collector_registry.gd) | Unit baseclass → collector class |
| [`SaveLoader`](../scripts/sim/save/save_loader.gd) | JSON snapshots now; SQLite probe + future loader |

## Matrix reporting

```bash
python3 development/godot/report_matrix.py
```

Auto-counts pytest `def test_*` vs GUT `func test_*` for Appendix C.

## Adding a building / unit

1. Edit YAML under `content/objects/`.
2. `./development/godot/sync.sh --skip-tests`
3. Port or add GUT case; run full sync.
