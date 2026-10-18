#!/usr/bin/env python3
"""Extract production rows from a legacy UH .sqlite save (building producer state)."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path, limit: int = 10000) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
		if "production" not in tables:
			return []
		rows = con.execute(
			"""
			SELECT rowid, state, owner, prod_line_id, remaining_ticks,
			       _pause_old_state, creation_tick
			FROM production
			ORDER BY owner, prod_line_id
			LIMIT ?
			""",
			(limit,),
		).fetchall()
	finally:
		con.close()
	out: list[dict] = []
	for rowid, state, owner, prod_line_id, remaining, pause_old, creation in rows:
		entry = {
			"rowid": int(rowid),
			"owner_worldid": int(owner),
			"prod_line_id": int(prod_line_id),
			"state": int(state),
			"remaining_ticks": int(remaining),
			"creation_tick": int(creation),
		}
		if pause_old is not None:
			entry["pause_old_state"] = int(pause_old)
		out.append(entry)
	return out


def main() -> int:
	if len(sys.argv) < 3:
		print(
			"usage: sqlite_extract_production.py save.sqlite out.json [limit]",
			file=sys.stderr,
		)
		return 1
	path = Path(sys.argv[1])
	out = Path(sys.argv[2])
	limit = int(sys.argv[3]) if len(sys.argv) > 3 else 10000
	data = extract(path, limit=limit)
	out.write_text(json.dumps(data, indent=2), encoding="utf-8")
	print("Wrote %s (%s production rows)" % (out, len(data)))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
