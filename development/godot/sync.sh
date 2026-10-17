#!/usr/bin/env bash
# Regenerate Godot exports and run the test suite (local parity with CI).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "==> export_content.py"
python3 development/godot/export_content.py

echo "==> export A1 extras (menu, grounds, audio)"
python3 development/godot/export_build_menu.py
python3 development/godot/export_grounds.py
python3 development/godot/export_audio.py

echo "==> export_gfx.py"
python3 development/godot/export_gfx.py --auto
python3 development/godot/export_gfx.py --auto --multi-frame --stems lumberjackcamp,stonemason,farm

echo "==> export_maps.py"
python3 development/godot/export_maps.py

echo "==> export_unit_gfx.py"
python3 development/godot/export_unit_gfx.py

echo "==> validate_content.py"
python3 development/godot/validate_content.py

echo "==> report_matrix.py"
python3 development/godot/report_matrix.py

echo "==> parity scenarios → godot/resources/parity"
mkdir -p godot/resources/parity
cp development/godot/parity/scenarios/*.json godot/resources/parity/
cp development/godot/parity/map_specs.json godot/resources/parity/

if [[ "${1:-}" == "--skip-tests" ]]; then
	echo "Skipping GUT (--skip-tests)."
	exit 0
fi

echo "==> sqlite save smoke"
python3 development/godot/sqlite_save_smoke.py

echo "==> sqlite fixture matrix"
python3 development/godot/sqlite_fixture_matrix.py

echo "==> export manifest"
python3 development/godot/write_export_manifest.py

echo "==> run_tests.sh"
./godot/run_tests.sh

if [[ "${1:-}" == "--parity" ]]; then
	echo "==> parity run_all.sh"
	./development/godot/parity/run_all.sh
fi
