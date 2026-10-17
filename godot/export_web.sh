#!/usr/bin/env bash
# Export Godot PoC for browser (Web / WASM). Fails fast if Godot or templates are missing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="$ROOT/godot"
OUT_DIR="$GODOT_DIR/build/web"
PRESET_NAME="Web"
EXPORT_PATH="build/web/index.html"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot not found on PATH (need Godot 4.3+ with export support)" >&2
	exit 1
fi

GODOT_VERSION="$(godot --version 2>/dev/null | head -1 || true)"
if [[ -z "$GODOT_VERSION" ]]; then
	echo "error: could not read godot --version" >&2
	exit 1
fi
if [[ "$GODOT_VERSION" != 4.3* ]]; then
	echo "warning: expected Godot 4.3.x export templates; got: $GODOT_VERSION" >&2
fi

TEMPLATE_VER="4.3.stable"
TEMPLATE_DIR="${GODOT_EXPORT_TEMPLATES:-$HOME/.local/share/godot/export_templates}/$TEMPLATE_VER"
if [[ ! -f "$TEMPLATE_DIR/web_nothreads_release.zip" && ! -f "$TEMPLATE_DIR/web_release.zip" ]]; then
	echo "error: missing web export templates in $TEMPLATE_DIR" >&2
	echo "Install Godot_v4.3-stable_export_templates.tpz via Editor → Manage Export Templates," >&2
	echo "or unzip into: $TEMPLATE_DIR" >&2
	exit 1
fi

if [[ ! -f "$GODOT_DIR/export_presets.cfg" ]]; then
	echo "error: $GODOT_DIR/export_presets.cfg not found" >&2
	exit 1
fi

if ! grep -q 'name="Web"' "$GODOT_DIR/export_presets.cfg"; then
	echo "error: export preset '$PRESET_NAME' not found in export_presets.cfg" >&2
	exit 1
fi

echo "==> Refresh content exports"
python3 "$ROOT/development/godot/export_content.py"
python3 "$ROOT/development/godot/export_gfx.py"
python3 "$ROOT/development/godot/validate_content.py"

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"/*
echo "==> Export Web → $GODOT_DIR/$EXPORT_PATH"
godot --headless --path "$GODOT_DIR" --export-release "$PRESET_NAME" "$EXPORT_PATH"

if [[ ! -f "$OUT_DIR/index.html" ]]; then
	echo "error: export finished but $OUT_DIR/index.html is missing" >&2
	exit 1
fi

if [[ ! -f "$OUT_DIR/index.wasm" && ! -f "$OUT_DIR/index.pck" ]]; then
	echo "error: export looks incomplete (no index.wasm or index.pck in $OUT_DIR)" >&2
	exit 1
fi

echo "OK: web build at $OUT_DIR"
