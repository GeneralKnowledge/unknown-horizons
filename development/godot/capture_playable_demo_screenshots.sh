#!/usr/bin/env bash
# Headless PNG captures of the playable settlement demo (title + in-game beats).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/godot/docs/screenshots}"
mkdir -p "$OUT_DIR"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot not on PATH" >&2
	exit 1
fi

echo "==> Godot import (global class cache)"
xvfb-run -a godot --path "$ROOT/godot" --display-driver x11 --rendering-driver opengl3 --import --quit

echo "==> Content exports (minimal for gfx)"
python3 "$ROOT/development/godot/export_content.py"
python3 "$ROOT/development/godot/export_gfx.py" --auto
python3 "$ROOT/development/godot/export_maps.py"

capture_preset() {
	local preset="$1"
	local outfile="$2"
	local run=(godot --path "$ROOT/godot")
	run+=(--display-driver x11 --rendering-driver opengl3)
	run+=(--resolution 1280x720)
	run+=(res://scenes/poc_main.tscn)
	run+=(--)
	run+=(--screenshot-preset="$preset")
	run+=(--screenshot-out="$outfile")
	run+=(--audio-driver Dummy)
	echo "==> Capture preset=$preset → $outfile"
	if command -v xvfb-run >/dev/null 2>&1; then
		xvfb-run -a "${run[@]}"
	else
		"${run[@]}"
	fi
	test -f "$outfile"
}

capture_preset title "$OUT_DIR/demo_title_menu.png"
capture_preset boards "$OUT_DIR/demo_boards_step.png"
capture_preset clay_hint "$OUT_DIR/demo_clay_deposit_marker.png"
capture_preset success "$OUT_DIR/demo_success_overlay.png"

if [[ -x "$ROOT/development/godot/capture_shareable_demo.sh" ]]; then
	echo "==> Shareable island marketing frame"
	"$ROOT/development/godot/capture_shareable_demo.sh" "$OUT_DIR/shareable_island.png"
fi

echo "OK: screenshots in $OUT_DIR"
