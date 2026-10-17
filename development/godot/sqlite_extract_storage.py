#!/usr/bin/env python3
"""Extract storage rows from a legacy UH .sqlite save (building inventories)."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path, limit: int = 5000) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		if "storage" not in {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}:
			return []
		rows = con.execute(
			"SELECT object, resource, amount FROM storage LIMIT ?",
			(limit,),
		).fetchall()
	finally:
		con.close()
	return [
		{"worldid": int(obj), "resource_id": int(res), "amount": int(amount)}
		for obj, res, amount in rows
	]


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_storage.py save.sqlite out.json [limit]", file=sys.stderr)
		return 1
	path = Path(sys.argv[1])
	out = Path(sys.argv[2])
	limit = int(sys.argv[3]) if len(sys.argv) > 3 else 5000
	data = extract(path, limit=limit)
	out.write_text(json.dumps(data, indent=2), encoding="utf-8")
	print("Wrote %s (%s storage rows)" % (out, len(data)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
