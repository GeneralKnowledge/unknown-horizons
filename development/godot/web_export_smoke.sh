#!/usr/bin/env bash
# Post-export checks for the browser demo (CI + local).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_DIR="$ROOT/godot/build/web"

if [[ ! -f "$WEB_DIR/index.html" ]]; then
	echo "error: missing $WEB_DIR/index.html — run ./godot/export_web.sh first" >&2
	exit 1
fi

if [[ ! -f "$WEB_DIR/index.wasm" && ! -f "$WEB_DIR/index.pck" ]]; then
	echo "error: web export incomplete (no index.wasm or index.pck)" >&2
	exit 1
fi

grep -q "index" "$WEB_DIR/index.html" || {
	echo "error: index.html looks invalid" >&2
	exit 1
}

echo "OK: web export smoke (artifacts present)"

if command -v godot >/dev/null 2>&1; then
	echo "==> Headless playable demo config smoke"
	godot --headless --path "$ROOT/godot" -s addons/gut/gut_cmdln.gd \
		-gdir=res://tests/integration \
		-gfile=test_playable_lumber_delivery.gd \
		-gexit \
		-ginclude_subdirs=false
fi
