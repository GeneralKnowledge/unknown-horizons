#!/usr/bin/env bash
# Optional M7 T1m: legacy Python inventory after 128 ticks on fire.sqlite (needs FIFE).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SAVE="$ROOT/legacy/tests/game/fixtures/fire.sqlite"
OUT="${1:-/tmp/legacy_fire_tick128.json}"
TICKS="${TICKS:-128}"
code=0
python3 "$ROOT/development/godot/sqlite_m7_legacy_fire_ticks.py" "$SAVE" "$OUT" --ticks "$TICKS" || code=$?
if [[ "$code" -eq 2 ]]; then
	echo "FIFE not installed — T1m skipped." >&2
	echo "Build legacy UH per legacy/README.md or legacy/development/docker/Dockerfile, then re-run." >&2
	echo "Godot-side tick parity is covered by T1l in ./godot/run_tests.sh (no FIFE)." >&2
	exit 2
fi
exit "$code"
