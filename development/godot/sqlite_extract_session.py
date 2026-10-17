#!/usr/bin/env python3
"""Extract session header fields from a legacy UH save (tick estimate, worldids)."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


TICK_QUERIES = (
	"SELECT MAX(tick) FROM production_state_history",
	"SELECT MAX(tick) FROM trade_history",
	"SELECT MAX(tick) FROM building_collector_job_history",
	"SELECT MAX(creation_tick) FROM production",
	"SELECT MAX(creation_tick) FROM building_collector",
)

WORLDID_TABLES = ("building", "unit", "settlement", "storage")


def _tables(con: sqlite3.Connection) -> set[str]:
	return {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}


def estimate_cur_tick(con: sqlite3.Connection) -> int:
	candidates: list[int] = []
	for q in TICK_QUERIES:
		try:
			val = con.execute(q).fetchone()[0]
		except sqlite3.OperationalError:
			continue
		if val is None:
			continue
		candidates.append(abs(int(val)))
	return max(candidates) if candidates else 0


def estimate_next_worldid(con: sqlite3.Connection) -> int:
	tables = _tables(con)
	max_id = 0
	for table in WORLDID_TABLES:
		if table not in tables:
			continue
		try:
			row = con.execute(f"SELECT MAX(rowid) FROM {table}").fetchone()
		except sqlite3.OperationalError:
			continue
		if row and row[0] is not None:
			max_id = max(max_id, int(row[0]))
	return max_id + 1


def extract(path: Path) -> dict:
	con = sqlite3.connect(str(path))
	try:
		meta = {}
		if "metadata" in _tables(con):
			meta = {
				str(k): str(v)
				for k, v in con.execute("SELECT name, value FROM metadata")
			}
		return {
			"savegamerev": int(meta.get("savegamerev", "0") or "0"),
			"map_name": meta.get("map_name", ""),
			"estimated_cur_tick": estimate_cur_tick(con),
			"next_worldid": estimate_next_worldid(con),
		}
	finally:
		con.close()


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_session.py save.sqlite out.json", file=sys.stderr)
		return 1
	data = extract(Path(sys.argv[1]))
	Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print("Wrote %s" % sys.argv[2])
	return 0


if __name__ == "__main__":
	sys.exit(main())
