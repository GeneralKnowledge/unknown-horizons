#!/usr/bin/env bash
# Render shareable_demo.tscn to a PNG (CI / marketing). Requires Godot 4.3+ and xvfb on Linux CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/godot/build/shareable_demo.png}"
mkdir -p "$(dirname "$OUT")"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot not on PATH" >&2
	exit 1
fi

echo "==> Godot import (global class cache)"
xvfb-run -a godot --path "$ROOT/godot" --display-driver x11 --rendering-driver opengl3 --import --quit

echo "==> Content exports (minimal for gfx)"
python3 "$ROOT/development/godot/export_content.py"
python3 "$ROOT/development/godot/export_gfx.py" --auto
python3 "$ROOT/development/godot/export_gfx.py" --auto --multi-frame --stems lumberjackcamp,stonemason,farm

RUN=(godot --path "$ROOT/godot")
RUN+=(--display-driver x11 --rendering-driver opengl3)
RUN+=(--resolution 1280x720)
RUN+=(res://scenes/shareable_demo.tscn)
RUN+=(--)
RUN+=(--screenshot-out="$OUT")

if command -v xvfb-run >/dev/null 2>&1; then
	echo "==> Capture via xvfb-run (OpenGL3) → $OUT"
	xvfb-run -a "${RUN[@]}"
else
	echo "==> Capture (OpenGL3) → $OUT"
	"${RUN[@]}"
fi

test -f "$OUT"
echo "OK: $OUT"
