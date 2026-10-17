#!/usr/bin/env python3
"""Compare normalized legacy vs Godot parity traces (or Godot vs golden)."""

from __future__ import annotations

import argparse
import difflib
import json
import sys
from pathlib import Path

from development.godot.parity.trace_format import load_trace, normalize_trace

PARITY_DIR = Path(__file__).resolve().parent
GOLDEN_DIR = PARITY_DIR / "golden"


def _json_lines(data: dict) -> list[str]:
	return json.dumps(data, indent=2, sort_keys=True).splitlines(keepends=True)


def compare(a: dict, b: dict, label_a: str, label_b: str) -> bool:
	na = normalize_trace(a)
	nb = normalize_trace(b)
	if na == nb:
		print("OK traces match (%s vs %s)" % (label_a, label_b))
		return True
	diff = difflib.unified_diff(
		_json_lines(na),
		_json_lines(nb),
		fromfile=label_a,
		tofile=label_b,
	)
	sys.stdout.writelines(diff)
	return False


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--legacy", type=Path)
	parser.add_argument("--godot", type=Path)
	parser.add_argument("--golden", type=Path, help="Compare godot trace to golden file")
	parser.add_argument("--scenario", type=str, help="Scenario id for golden/ path lookup")
	args = parser.parse_args()

	if args.godot and args.golden:
		ok = compare(
			load_trace(args.godot),
			load_trace(args.golden),
			str(args.godot),
			str(args.golden),
		)
		return 0 if ok else 1

	if args.godot and args.scenario:
		golden = GOLDEN_DIR / ("%s.godot.json" % args.scenario)
		if not golden.is_file():
			print("Missing golden trace %s (run update_golden.sh)" % golden, file=sys.stderr)
			return 1
		ok = compare(load_trace(args.godot), load_trace(golden), str(args.godot), str(golden))
		return 0 if ok else 1

	if args.legacy and args.godot:
		ok = compare(
			load_trace(args.legacy),
			load_trace(args.godot),
			"legacy",
			"godot",
		)
		return 0 if ok else 1

	parser.print_help()
	return 1


if __name__ == "__main__":
	sys.exit(main())
