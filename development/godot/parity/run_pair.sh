#!/usr/bin/env bash
# Run legacy + Godot parity for one scenario, then compare (or Godot vs golden if legacy skipped).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
export PYTHONPATH="$ROOT${PYTHONPATH:+:$PYTHONPATH}"
PARITY="$(cd "$(dirname "$0")" && pwd)"
RAW_SCENARIO="${1:?usage: run_pair.sh path/to/scenario.json}"
# Godot reads scenarios from res:// (sandbox-safe).
if [[ "$RAW_SCENARIO" == *"/development/godot/parity/scenarios/"* ]]; then
	SCENARIO_NAME="$(basename "$RAW_SCENARIO")"
	SCENARIO="$ROOT/godot/resources/parity/$SCENARIO_NAME"
	mkdir -p "$ROOT/godot/resources/parity"
	cp "$RAW_SCENARIO" "$SCENARIO"
else
	SCENARIO="$RAW_SCENARIO"
fi
SCENARIO="${SCENARIO:?}"
OUT_DIR="${OUT_DIR:-$ROOT/.parity-out}"
mkdir -p "$OUT_DIR"
SCENARIO_ID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['id'])" "$SCENARIO")"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	GODOT="/usr/local/bin/godot"
fi

LEGACY_OUT="$OUT_DIR/trace_legacy_${SCENARIO_ID}.json"
GODOT_OUT="$OUT_DIR/trace_godot_${SCENARIO_ID}.json"
GODOT_USER_OUT=""

LEGACY_OK=0
python3 "$PARITY/run_legacy.py" "$RAW_SCENARIO" --out "$LEGACY_OUT" || LEGACY_OK=$?

GODOT_SCENARIO="res://resources/parity/$(basename "$SCENARIO")"
cd "$ROOT/godot"
timeout 120 "$GODOT" --headless --path . res://scenes/parity_runner.tscn -- "$GODOT_SCENARIO" --out "$GODOT_OUT"
test -f "$GODOT_OUT"

cd "$ROOT"
if [[ "$LEGACY_OK" -eq 0 ]]; then
	python3 "$PARITY/compare_traces.py" --legacy "$LEGACY_OUT" --godot "$GODOT_OUT"
else
	echo "Legacy runner unavailable (exit $LEGACY_OK); comparing Godot trace to golden."
	python3 "$PARITY/compare_traces.py" --godot "$GODOT_OUT" --scenario "$SCENARIO_ID"
fi
