#!/usr/bin/env python3
"""Smoke-test legacy SQLite savegames (tables present, basic metadata readable)."""

from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_FIXTURE = REPO_ROOT / "tests/game/fixtures/savegame-rev-76.sqlite"


def smoke(path: Path) -> None:
	if not path.is_file():
		raise FileNotFoundError(path)
	header = path.read_bytes()[:16]
	if not header.startswith(b"SQLite format 3"):
		raise ValueError("Not a SQLite 3 file: %s" % path)
	con = sqlite3.connect(str(path))
	try:
		tables = {
			row[0]
			for row in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}
		required = {"metadata", "building", "settlement"}
		missing = required - tables
		if missing:
			raise RuntimeError("Missing tables: %s" % sorted(missing))
		(meta_count,) = con.execute("SELECT COUNT(*) FROM metadata").fetchone()
		(build_count,) = con.execute("SELECT COUNT(*) FROM building").fetchone()
		print(
			"OK %s — metadata rows=%s building rows=%s (%s tables)"
			% (path.name, meta_count, build_count, len(tables))
		)
	finally:
		con.close()


def main() -> int:
	path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_FIXTURE
	smoke(path)
	return 0


if __name__ == "__main__":
	sys.exit(main())
