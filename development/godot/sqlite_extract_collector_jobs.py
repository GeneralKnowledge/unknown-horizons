#!/usr/bin/env python3
"""Summarize legacy collector job / path tables (diagnostics; Godot does not replay yet)."""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


def extract(path: Path) -> dict:
	con = sqlite3.connect(str(path))
	try:
		tables = {
			r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
		}
		out: dict = {"tables": {}}
		for name in (
			"building_collector_job_history",
			"collector_job",
			"unit_path",
		):
			if name not in tables:
				out["tables"][name] = {"present": False, "rows": 0}
				continue
			count = con.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]
			out["tables"][name] = {"present": True, "rows": int(count)}
	finally:
		con.close()
	return out


def main() -> int:
	if len(sys.argv) < 3:
		print(
			"usage: sqlite_extract_collector_jobs.py save.sqlite out.json",
			file=sys.stderr,
		)
		return 1
	data = extract(Path(sys.argv[1]))
	Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print("Wrote %s" % sys.argv[2])
	return 0


if __name__ == "__main__":
	sys.exit(main())
