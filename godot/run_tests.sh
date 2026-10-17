#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	GODOT="${HOME}/bin/godot"
fi
if [[ ! -x "$GODOT" ]] && [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then
	GODOT="/tmp/Godot_v4.3-stable_linux.x86_64"
fi
cd "$ROOT"
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
