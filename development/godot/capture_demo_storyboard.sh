#!/usr/bin/env bash
# Storyboard PNGs: living village showcase (D1) + legacy short-demo beats.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/godot/docs/screenshots/storyboard}"
mkdir -p "$OUT_DIR"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	if [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then
		GODOT="/tmp/Godot_v4.3-stable_linux.x86_64"
	else
		echo "error: godot not on PATH" >&2
		exit 1
	fi
fi

echo "==> Godot import"
xvfb-run -a "$GODOT" --path "$ROOT/godot" --display-driver x11 --rendering-driver opengl3 --import --quit

capture_preset() {
	local preset="$1"
	local outfile="$2"
	local run=("$GODOT" --path "$ROOT/godot")
	run+=(--display-driver x11 --rendering-driver opengl3 --resolution 1280x720)
	run+=(res://scenes/poc_main.tscn --)
	run+=(--screenshot-preset="$preset" --screenshot-out="$outfile" --audio-driver Dummy)
	echo "==> preset=$preset → $outfile"
	xvfb-run -a "${run[@]}"
	test -f "$outfile"
}

# D1 living village (pre-built + sim warmup inside preset)
capture_preset showcase_wide "$OUT_DIR/01_village_wide.png"
capture_preset showcase_lumber "$OUT_DIR/02_lumber_working.png"
capture_preset showcase_food "$OUT_DIR/03_food_chain.png"
capture_preset showcase_brickyard "$OUT_DIR/04_brickyard.png"
capture_preset showcase_toolmaker "$OUT_DIR/05_toolmaker.png"
capture_preset showcase_dlc "$OUT_DIR/06_dlc_smokery.png"
capture_preset showcase_hud "$OUT_DIR/07_hud_inspect.png"

# Short playable demo beats (title + milestones)
capture_preset title "$OUT_DIR/08_title_menu.png"

echo "OK: storyboard in $OUT_DIR"
