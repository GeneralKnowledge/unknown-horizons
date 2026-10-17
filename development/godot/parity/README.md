# Dual-run parity harness

Runs the same **scenario JSON** on legacy Horizons (Python sim) and the Godot port, then compares normalized traces.

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

Default GitHub workflow runs GUT only. Optional local full check:

```bash
./development/godot/sync.sh --parity
```
