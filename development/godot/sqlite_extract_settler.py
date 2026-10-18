#!/usr/bin/env python3
"""Extract settler (residential) rows from a legacy UH .sqlite save."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		if "settler" not in {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}:
			return []
		rows = con.execute(
			"SELECT rowid, inhabitants, last_tax_payed FROM settler"
		).fetchall()
	finally:
		con.close()
	return [
		{
			"building_worldid": int(rowid),
			"inhabitants": int(inhabitants if inhabitants is not None else 0),
			"last_tax_payed": int(last_tax if last_tax is not None else 0),
		}
		for rowid, inhabitants, last_tax in rows
	]


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_settler.py save.sqlite out.json", file=sys.stderr)
		return 1
	data = extract(Path(sys.argv[1]))
	Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print("Wrote %s (%s settler rows)" % (sys.argv[2], len(data)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
