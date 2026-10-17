#!/usr/bin/env bash
# Regenerate all Godot export artifacts (content, gfx, manifest). No GUT.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
PYTHON="${PYTHON:-python3}"
FAILURES=()

_run() {
	local name="$1"
	shift
	echo "==> $name"
	if "$@"; then
		return 0
	fi
	echo "FAIL: $name" >&2
	FAILURES+=("$name")
	return 1
}

set -e
_run export_content.py "$PYTHON" development/godot/export_content.py
_run export_a1_extras "$PYTHON" development/godot/export_build_menu.py && "$PYTHON" development/godot/export_grounds.py && "$PYTHON" development/godot/export_audio.py
_run export_gfx.py "$PYTHON" development/godot/export_gfx.py --auto
set +e
"$PYTHON" development/godot/export_gfx.py --auto --multi-frame --stems lumberjackcamp,stonemason,farm
set -e
_run validate_content.py "$PYTHON" development/godot/validate_content.py
set +e
[[ -f development/godot/export_maps.py ]] && _run export_maps.py "$PYTHON" development/godot/export_maps.py
[[ -f development/godot/export_unit_gfx.py ]] && _run export_unit_gfx.py "$PYTHON" development/godot/export_unit_gfx.py
set -e

"$PYTHON" development/godot/write_export_manifest.py "${FAILURES[@]}"
MANIFEST_EXIT=$?

if ((${#FAILURES[@]} > 0)); then
	echo "export_all finished with failures: ${FAILURES[*]}" >&2
	exit 1
fi
exit "$MANIFEST_EXIT"
