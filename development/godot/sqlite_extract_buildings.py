#!/usr/bin/env python3
"""Extract building rows from a legacy UH .sqlite save for Godot SqliteSaveLoader."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path, limit: int = 500, include_skipped: bool = False) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		rows = con.execute(
			"SELECT rowid, type, x, y, location, rotation, level FROM building LIMIT ?",
			(limit,),
		).fetchall()
		total = con.execute("SELECT COUNT(*) FROM building").fetchone()[0]
	finally:
		con.close()
	out = []
	for rowid, typ, x, y, location, rotation, level in rows:
		out.append(
			{
				"worldid": int(rowid),
				"building_id": int(typ),
				"x": int(x),
				"y": int(y),
				"location": int(location),
				"rotation": int(rotation),
				"level": int(level),
			}
		)
	if include_skipped and total > limit:
		out.append(
			{
				"_skipped": True,
				"reason": "limit",
				"limit": limit,
				"total_buildings": int(total),
			}
		)
	return out


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_buildings.py save.sqlite out.json [limit]", file=sys.stderr)
		return 1
	path = Path(sys.argv[1])
	out = Path(sys.argv[2])
	limit = int(sys.argv[3]) if len(sys.argv) > 3 else 500
	include_skipped = "--include-skipped" in sys.argv
	data = extract(path, limit=limit, include_skipped=include_skipped)
	out.write_text(json.dumps(data, indent=2), encoding="utf-8")
	print("Wrote %s (%s buildings)" % (out, len(data)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
