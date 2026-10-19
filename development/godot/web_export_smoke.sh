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

# Title menu strings for three demo modes (embedded in poc_main export).
for needle in \
	"Start settlement demo (short)" \
	"Northern expedition (full demo)" \
	"Living village showcase" \
	"Continue JSON save"; do
	grep -rq "$needle" "$ROOT/godot/scripts/view/start_menu_panel.gd" || {
		echo "error: missing menu string: $needle" >&2
		exit 1
	}
done
echo "OK: browser demo menu strings present"

if command -v godot >/dev/null 2>&1; then
	echo "==> Headless playable demo integration smoke"
	(cd "$ROOT/godot" && godot --headless --import --path . >/dev/null)
	(cd "$ROOT/godot" && godot --headless --path . -s addons/gut/gut_cmdln.gd \
		-gconfig=.gutconfig.json -gexit -gselect=test_playable_lumber_delivery)
fi
