#!/usr/bin/env bash
# Deprecated wrapper — use record_demo_slice_video.sh (auto-loaded slice, no xdotool).
exec "$(cd "$(dirname "$0")" && pwd)/record_demo_slice_video.sh" "${1:-}"
