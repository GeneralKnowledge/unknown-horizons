#!/usr/bin/env python3
"""Extract unit + wild-animal rows from a legacy UH save."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

# Known ship unit types (GameConstants.UNITS); extend as exports grow.
SHIP_UNIT_TYPE_IDS = frozenset(
	{
		1000001,  # HUKER_SHIP
		1000005,  # PIRATE_SHIP
		1000006,  # TRADER_SHIP
	}
)

SHIP_TABLES = (
	"trader_ships",
	"fleet_ship",
	"pirate_ships",
	"ai_ship",
	"ai_combat_ship",
)


def _tables(con: sqlite3.Connection) -> set[str]:
	return {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}


def _ship_unit_rowids(con: sqlite3.Connection, tables: set[str]) -> set[int]:
	out: set[int] = set()
	for table in SHIP_TABLES:
		if table not in tables:
			continue
		try:
			for rowid, in con.execute(f"SELECT rowid FROM {table}"):
				out.add(int(rowid))
		except sqlite3.OperationalError:
			continue
	return out


def extract(path: Path, limit: int = 2000) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		tables = _tables(con)
		if "unit" not in tables:
			return []
		has_collector = "building_collector" in tables
		has_wild = "wildanimal" in tables
		collector_home: dict[int, int] = {}
		if has_collector:
			for rowid, home, _ct in con.execute(
				"SELECT rowid, home_building, creation_tick FROM building_collector"
			):
				if home is not None:
					collector_home[int(rowid)] = int(home)
		wild_ids: set[int] = set()
		if has_wild:
			for rowid, _health, _repro in con.execute(
				"SELECT rowid, health, can_reproduce FROM wildanimal"
			):
				wild_ids.add(int(rowid))
		ship_ids = _ship_unit_rowids(con, tables)
		rows = con.execute(
			"SELECT rowid, type, x, y, location, owner FROM unit LIMIT ?",
			(limit,),
		).fetchall()
	finally:
		con.close()
	out: list[dict] = []
	for rowid, typ, x, y, location, owner in rows:
		entry = {
			"worldid": int(rowid),
			"unit_type_id": int(typ),
			"x": int(x) if x is not None else 0,
			"y": int(y) if y is not None else 0,
			"location": int(location) if location is not None else 0,
			"owner": int(owner),
		}
		rid = int(rowid)
		typ_id = int(typ)
		if rid in wild_ids:
			entry["kind"] = "wild_animal"
		elif rid in collector_home:
			entry["kind"] = "collector"
			entry["home_building_worldid"] = collector_home[rid]
		elif rid in ship_ids or typ_id in SHIP_UNIT_TYPE_IDS:
			entry["kind"] = "ship"
		else:
			entry["kind"] = "unit"
		out.append(entry)
	return out


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_units.py save.sqlite out.json [limit]", file=sys.stderr)
		return 1
	limit = int(sys.argv[3]) if len(sys.argv) > 3 else 2000
	data = extract(Path(sys.argv[1]), limit=limit)
	Path(sys.argv[2]).write_text(json.dumps(data, indent=2), encoding="utf-8")
	print("Wrote %s (%s units)" % (sys.argv[2], len(data)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
