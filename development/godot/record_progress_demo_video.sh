#!/usr/bin/env bash
# Record a short progress demo (Godot boot splash → title → settlement demo).
# Usage: ./development/godot/record_progress_demo_video.sh [output.mp4]
# Requires: godot, ffmpeg, xdotool, DISPLAY (e.g. :1 on cloud VM).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/godot/build/progress_demo.mp4}"
mkdir -p "$(dirname "$OUT")"
export DISPLAY="${DISPLAY:-:0}"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot not on PATH" >&2
	exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "error: ffmpeg required" >&2
	exit 1
fi

echo "==> Content exports (match CI)"
python3 "$ROOT/development/godot/export_content.py"
python3 "$ROOT/development/godot/export_gfx.py" --auto
python3 "$ROOT/development/godot/export_maps.py"

echo "==> Godot import"
godot --headless --path "$ROOT/godot" --import --quit

W=1280
H=720
FPS=30
DUR=45

echo "==> Recording ${DUR}s @ ${W}x${H} → $OUT"
ffmpeg -y -f x11grab -video_size "${W}x${H}" -framerate "$FPS" -i "$DISPLAY" \
	-t "$DUR" -c:v libx264 -preset ultrafast -pix_fmt yuv420p "$OUT" &
FFPID=$!

sleep 1
godot --path "$ROOT/godot" --display-driver x11 --rendering-driver opengl3 \
	--resolution "${W}x${H}" --position 0,0 \
	--audio-driver Dummy \
	res://scenes/poc_main.tscn &
GPID=$!

sleep 4
if command -v xdotool >/dev/null 2>&1; then
	WID=$(xdotool search --name "Unknown Horizons" 2>/dev/null | head -1 || true)
	if [[ -n "${WID:-}" ]]; then
		xdotool windowactivate --sync "$WID"
		# Title screen: first primary button (~Start settlement demo)
		xdotool mousemove --window "$WID" 640 380 click 1
		sleep 3
		xdotool key --window "$WID" b
		sleep 2
		# Pan view slightly (middle-drag) and let sim run
		xdotool mousedown --window "$WID" 2
		xdotool mousemove --window "$WID" 700 400
		xdotool mouseup --window "$WID" 2
	fi
fi

wait "$FFPID" || true
kill "$GPID" 2>/dev/null || true
wait "$GPID" 2>/dev/null || true

if [[ ! -s "$OUT" ]]; then
	echo "error: recording missing or empty" >&2
	exit 1
fi
echo "OK: $OUT"
