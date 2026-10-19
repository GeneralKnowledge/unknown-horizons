# Dual-run parity harness

Runs the same **scenario JSON** on legacy Horizons (Python sim) and the Godot port, then compares normalized traces.

## Parity roadmap (stages)

| Stage | Focus | Scenarios |
|-------|--------|-----------|
| **1** | Core loop | `wood`, `warehouse_collector`, `snapshot_roundtrip` |
| **2** | Tier-1 + tier-2 economy | `tier1_starter`, `stonemason`, **`brickyard`**, `farm_crop` |
| **3** | Chains + save fidelity + demo map | **`toolmaker`**, **`snapshot_mid_production`**, **`brickyard_development`**, **`weaver`**, **`salt_ponds`**, **`bakery`**, **`pavilion`** |

Next targets (Godot-only): bakery/pavilion chains, producer state in JSON snapshots, longer **`development`** map scenarios. Legacy Python dual-run requires **`fife`** locally and is **not** a merge gate ([`LEGACY_IMPORT_FROZEN.md`](../../godot/docs/LEGACY_IMPORT_FROZEN.md)).

**Legacy `.sqlite` (frozen):** CI uses Godot **T1l** tick goldens only; optional FIFE probe: `RUN_T1M=1` + `sqlite_m7_legacy_fire_ticks.py`.

## Quick start

```bash
# From repo root (Godot 4.3 on PATH)
./development/godot/parity/run_pair.sh development/godot/parity/scenarios/wood.json
./development/godot/parity/run_all.sh
```

Artifacts go to `.parity-out/` by default.

## Legacy Python side

Requires the **`fife`** module (full Unknown Horizons dev environment). If missing, `run_legacy.py` exits `2` and `run_pair.sh` compares the Godot trace to **golden** files under `golden/*.godot.json`.

```bash
python3 development/godot/parity/run_legacy.py development/godot/parity/scenarios/wood.json --out .parity-out/trace_legacy.json
```

## Godot side

```bash
cd godot
godot --headless --path . res://scenes/parity_runner.tscn -- res://resources/parity/wood.json --out ../.parity-out/trace_godot.json
```

Scenarios are copied to `godot/resources/parity/` during `sync.sh` (or by `run_pair.sh`).

## Update golden traces

```bash
./development/godot/parity/update_golden.sh
```

## Schema

- Map spec: [`map_specs.json`](map_specs.json)
- Scenario shape: [`schema.json`](schema.json)
- Trace normalization: [`trace_format.py`](trace_format.py)

## CI

[`.github/workflows/godot-tests.yml`](../../.github/workflows/godot-tests.yml) runs three jobs on `godot/**` changes:

| Job | What it runs |
|-----|----------------|
| **`gut`** | Full export pipeline + SQLite smoke/matrix + `./godot/run_tests.sh` |
| **`parity-golden`** | Godot traces vs `golden/*.godot.json` via `./development/godot/parity/run_all.sh` |
| **`web-export`** | `./godot/export_web.sh` (uses `export_all.sh` for content parity) |

Legacy Python dual-run still needs **`fife`** locally (`run_pair.sh`). Optional full local check:

```bash
./development/godot/sync.sh --parity
```
