#!/usr/bin/env python3
"""Read metadata rows from a legacy UH savegame SQLite file."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path) -> dict:
	con = sqlite3.connect(str(path))
	try:
		if "metadata" not in {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}:
			return {}
		return {
			str(k): str(v)
			for k, v in con.execute("SELECT name, value FROM metadata")
		}
	finally:
		con.close()


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_metadata.py save.sqlite out.json", file=sys.stderr)
		return 1
	data = extract(Path(sys.argv[1]))
	Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print("Wrote %s (%s keys)" % (sys.argv[2], len(data)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
