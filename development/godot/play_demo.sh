#!/usr/bin/env bash
# Quick path to the settlement demo (export content + open Godot).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
echo "==> Export content (buildings, constants, maps baseline)"
python3 development/godot/export_content.py
if python3 development/godot/export_maps.py 2>/dev/null; then
	:
else
	echo "note: export_maps skipped or failed — demo may still run on bundled maps"
fi
if command -v godot >/dev/null 2>&1; then
	GODOT=godot
elif [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then
	GODOT=/tmp/Godot_v4.3-stable_linux.x86_64
else
	echo "error: install Godot 4.3+ on PATH" >&2
	exit 1
fi
echo "==> Launch poc_main (settlement demo entry)"
exec "$GODOT" --path "$ROOT/godot" res://scenes/poc_main.tscn "$@"
