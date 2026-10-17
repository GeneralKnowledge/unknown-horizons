#!/usr/bin/env python3
"""Summarize godot-port paths useful for cherry-pick (run locally; optional CI)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
UPSTREAM = REPO / "godot" / "resources" / "upstream" / "godot-port"
CLONE_URL = "https://github.com/unknown-horizons/godot-port.git"
BRANCH = "develop"

SCAN_PREFIXES = (
	"Assets/World/Context",
	"Assets/Player",
	"Assets/UI/TabWidgets",
)


def line_count(path: Path) -> int:
	return len(path.read_text(encoding="utf-8", errors="replace").splitlines())


def main() -> int:
	tmp = Path("/tmp/godot-port-inventory")
	if not (tmp / ".git").is_dir():
		subprocess.run(
			["git", "clone", "--depth", "1", "--branch", BRANCH, CLONE_URL, str(tmp)],
			check=True,
		)
	commit = subprocess.check_output(["git", "-C", str(tmp), "rev-parse", "HEAD"], text=True).strip()
	print(f"godot-port {BRANCH} @ {commit}\n")
	for prefix in SCAN_PREFIXES:
		root = tmp / prefix
		if not root.is_dir():
			continue
		print(f"## {prefix}")
		files = sorted(root.rglob("*.gd"))
		for f in files[:40]:
			print(f"  {f.relative_to(tmp)} ({line_count(f)} lines)")
		if len(files) > 40:
			print(f"  ... and {len(files) - 40} more")
		print()
	pinned = (UPSTREAM / "SOURCE_COMMIT.txt").read_text().strip() if (UPSTREAM / "SOURCE_COMMIT.txt").is_file() else ""
	if pinned and pinned != commit:
		print(f"warning: pinned SOURCE_COMMIT.txt ({pinned}) != clone ({commit})", file=sys.stderr)
		return 1
	return 0


if __name__ == "__main__":
	sys.exit(main())
