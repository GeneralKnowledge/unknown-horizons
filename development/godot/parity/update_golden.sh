#!/usr/bin/env bash
# Regenerate golden Godot traces (when legacy/FIFE unavailable).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PARITY="$(cd "$(dirname "$0")" && pwd)"
GOLDEN="$PARITY/golden"
GODOT="${GODOT:-godot}"
mkdir -p "$GOLDEN"
cd "$ROOT/godot"
for scenario in "$PARITY"/scenarios/*.json; do
	id="$(python3 -c "import json; print(json.load(open('$scenario'))['id'])")"
	out="$GOLDEN/${id}.godot.json"
	"$GODOT" --headless --path . res://scenes/parity_runner.tscn -- "$scenario" --out "$out"
	echo "Updated $out"
done
