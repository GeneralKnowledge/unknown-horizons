#!/usr/bin/env python3
"""Dump Godot inventory totals after N ticks on a legacy fixture (writes M7 golden JSON).

Prefer GUT (loads autoloads correctly):

  cd godot && WRITE_M7_GOLDEN=1 godot --headless --path . -s addons/gut/gut_cmdln.gd \\
    -gconfig=.gutconfig.json -gunit_test_name=tick128_inventory -gexit
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GODOT = os.environ.get("GODOT", "/tmp/Godot_v4.3-stable_linux.x86_64")
SCRIPT = REPO / "godot/scripts/tools/m7_tick_golden_runner.gd"


def main() -> int:
	if len(sys.argv) < 4:
		print(
			"usage: dump_m7_tick_golden.py fixture.sqlite out.json ticks",
			file=sys.stderr,
		)
		return 1
	fixture = Path(sys.argv[1]).resolve()
	out = Path(sys.argv[2]).resolve()
	ticks = int(sys.argv[3])
	out.parent.mkdir(parents=True, exist_ok=True)
	env = os.environ.copy()
	env["M7_FIXTURE"] = str(fixture)
	env["M7_TICKS"] = str(ticks)
	env["M7_OUT"] = str(out)
	cmd = [
		GODOT,
		"--headless",
		"--path",
		str(REPO / "godot"),
		"-s",
		str(SCRIPT),
	]
	proc = subprocess.run(cmd, env=env, capture_output=True, text=True)
	if proc.returncode != 0:
		print(proc.stdout, proc.stderr, file=sys.stderr)
		return proc.returncode
	print("Wrote", out)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
