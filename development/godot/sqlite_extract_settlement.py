#!/usr/bin/env python3
"""Extract settlement rows from a legacy UH .sqlite save."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path) -> list[dict]:
	con = sqlite3.connect(str(path))
	try:
		if "settlement" not in {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}:
			return []
		rows = con.execute("SELECT rowid, owner, island FROM settlement").fetchall()
		tax_by_settlement: dict[int, dict[int, float]] = {}
		if "settlement_level_properties" in {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}:
			for settlement_id, level, _upgrade, tax in con.execute(
				"SELECT settlement, level, upgrading_allowed, tax_setting "
				"FROM settlement_level_properties"
			):
				tax_by_settlement.setdefault(int(settlement_id), {})[int(level)] = float(tax)
	finally:
		con.close()
	out: list[dict] = []
	for rowid, owner, island in rows:
		entry: dict = {
			"rowid": int(rowid),
			"owner": int(owner),
			"island": int(island),
		}
		taxes = tax_by_settlement.get(int(rowid))
		if taxes:
			entry["tax_settings_by_level"] = {str(k): v for k, v in sorted(taxes.items())}
		out.append(entry)
	return out


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_settlement.py save.sqlite out.json", file=sys.stderr)
		return 1
	path = Path(sys.argv[1])
	out = Path(sys.argv[2])
	data = extract(path)
	out.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print("Wrote %s (%s settlements)" % (out, len(data)))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
