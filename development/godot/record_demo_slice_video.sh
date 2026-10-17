#!/usr/bin/env bash
# Record the curated settlement vertical slice (no clicks — auto-loaded scene + timeline).
# Usage: ./development/godot/record_demo_slice_video.sh [output.mp4]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/godot/docs/videos/settlement_demo_slice.mp4}"
mkdir -p "$(dirname "$OUT")"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot not on PATH" >&2
	exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "error: ffmpeg required" >&2
	exit 1
fi

W=1280
H=720
FPS=30
GAME_SEC=28
PAD=4
REC_SEC=$((GAME_SEC + PAD))

echo "==> Godot import"
xvfb-run -a godot --path "$ROOT/godot" --display-driver x11 --rendering-driver opengl3 --import --quit

echo "==> Content exports"
python3 "$ROOT/development/godot/export_content.py"
python3 "$ROOT/development/godot/export_gfx.py" --auto
python3 "$ROOT/development/godot/export_maps.py"

capture_cmd() {
	echo "==> Recording ${REC_SEC}s @ ${W}x${H} on $DISPLAY → $OUT"
	ffmpeg -y -f x11grab -video_size "${W}x${H}" -framerate "$FPS" \
		-i "$DISPLAY" -t "$REC_SEC" -c:v libx264 -preset ultrafast -pix_fmt yuv420p "$OUT" &
	local ffpid=$!
	sleep 1
	godot --path "$ROOT/godot" \
		--display-driver x11 --rendering-driver opengl3 \
		--resolution "${W}x${H}" --position 0,0 \
		--audio-driver Dummy \
		res://scenes/playable_slice.tscn -- \
		--video-slice=settlement_demo --video-duration="$GAME_SEC"
	wait "$ffpid" 2>/dev/null || true
}

if command -v xvfb-run >/dev/null 2>&1; then
	xvfb-run -a bash -c "$(declare -f capture_cmd); ROOT='$ROOT' OUT='$OUT' W=$W H=$H FPS=$FPS REC_SEC=$REC_SEC GAME_SEC=$GAME_SEC capture_cmd"
else
	capture_cmd
fi

if [[ ! -s "$OUT" ]]; then
	echo "error: recording missing or empty" >&2
	exit 1
fi
echo "OK: $OUT"
