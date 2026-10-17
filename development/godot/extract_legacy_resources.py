#!/usr/bin/env python3
"""Single entry point: extract original Unknown Horizons content for the Godot port.

Upstream game tree expected at ``legacy/`` (YAML, ``horizons/constants.py``,
``content/gfx/``, map SQLite, etc.). Outputs land under ``godot/resources/``.

This script does not duplicate extraction logic — it runs the same Python
exporters CI uses (see ``export_all.sh``). Copy this file plus the modules it
invokes into an upstream PR, or run from this monorepo:

  python3 development/godot/extract_legacy_resources.py --all

Typical shareable subset for "original resources → JSON + sprites":

  python3 development/godot/extract_legacy_resources.py --content --gfx

Save-game SQLite helpers (``sqlite_extract_*.py``) are separate; use them for
save parity, not art/audio export.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEV = Path(__file__).resolve().parent


def _run(label: str, argv: list[str]) -> None:
	print(f"==> {label}")
	subprocess.run(argv, cwd=ROOT, check=True)


def main() -> int:
	parser = argparse.ArgumentParser(
		description="Extract legacy UH resources into godot/resources/ (orchestrator)."
	)
	parser.add_argument(
		"--all",
		action="store_true",
		help="Full pipeline (content, menu/grounds/audio, gfx, validate, maps, units)",
	)
	parser.add_argument("--content", action="store_true", help="constants + buildings JSON")
	parser.add_argument(
		"--extras",
		action="store_true",
		help="build menu, ground tile defs, audio index",
	)
	parser.add_argument("--gfx", action="store_true", help="building PNGs + sprite manifests")
	parser.add_argument("--maps", action="store_true", help="ground maps from legacy SQLite")
	parser.add_argument("--units", action="store_true", help="unit gfx slice")
	parser.add_argument(
		"--validate",
		action="store_true",
		help="run validate_content.py after content export",
	)
	parser.add_argument(
		"--multi-frame-stems",
		default="lumberjackcamp,stonemason,farm",
		help="Comma stems for optional multi-frame gfx pass (with --gfx or --all)",
	)
	args = parser.parse_args()
	py = sys.executable

	if not any(
		(
			args.all,
			args.content,
			args.extras,
			args.gfx,
			args.maps,
			args.units,
			args.validate,
		)
	):
		parser.print_help()
		print(
			"\nNothing selected. Try: extract_legacy_resources.py --content --gfx",
			file=sys.stderr,
		)
		return 2

	do_content = args.all or args.content
	do_extras = args.all or args.extras
	do_gfx = args.all or args.gfx
	do_maps = args.all or args.maps
	do_units = args.all or args.units
	do_validate = args.all or args.validate

	if do_content:
		_run("export_content.py", [py, str(DEV / "export_content.py")])
	if do_extras:
		_run("export_build_menu.py", [py, str(DEV / "export_build_menu.py")])
		_run("export_grounds.py", [py, str(DEV / "export_grounds.py")])
		_run("export_audio.py", [py, str(DEV / "export_audio.py")])
	if do_gfx:
		_run("export_gfx.py --auto", [py, str(DEV / "export_gfx.py"), "--auto"])
		stems = args.multi_frame_stems.strip()
		if stems:
			_run(
				"export_gfx.py multi-frame",
				[
					py,
					str(DEV / "export_gfx.py"),
					"--auto",
					"--multi-frame",
					"--stems",
					stems,
				],
			)
	if do_validate:
		_run("validate_content.py", [py, str(DEV / "validate_content.py")])
	if do_maps and (DEV / "export_maps.py").is_file():
		_run("export_maps.py", [py, str(DEV / "export_maps.py")])
	if do_units and (DEV / "export_unit_gfx.py").is_file():
		_run("export_unit_gfx.py", [py, str(DEV / "export_unit_gfx.py")])

	if args.all:
		_run("write_export_manifest.py", [py, str(DEV / "write_export_manifest.py")])

	print("OK: legacy extraction finished")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
