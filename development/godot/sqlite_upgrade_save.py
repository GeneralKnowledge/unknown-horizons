#!/usr/bin/env python3
"""Lightweight save revision bump (76→77) without importing FIFE/horizons."""

from __future__ import annotations

import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path

TARGET_REV = 77
LEAST_UPGRADABLE = 76


def upgrade(path: Path, out_dir: Path | None = None) -> Path:
	path = path.resolve()
	con = sqlite3.connect(str(path))
	try:
		meta = {
			str(k): str(v)
			for k, v in con.execute("SELECT name, value FROM metadata")
		}
	finally:
		con.close()
	rev = int(meta.get("savegamerev", "0") or "0")
	if rev >= TARGET_REV:
		return path
	if rev < LEAST_UPGRADABLE:
		raise ValueError(f"Save rev {rev} is below least upgradable {LEAST_UPGRADABLE}")
	dest_dir = out_dir or Path(tempfile.mkdtemp(prefix="uh-upgraded-"))
	dest_dir.mkdir(parents=True, exist_ok=True)
	out = dest_dir / path.name
	shutil.copy2(path, out)
	con = sqlite3.connect(str(out))
	try:
		con.execute(
			"UPDATE metadata SET value = ? WHERE name = 'savegamerev'",
			(str(TARGET_REV),),
		)
		if con.total_changes == 0:
			con.execute(
				"INSERT INTO metadata(name, value) VALUES('savegamerev', ?)",
				(str(TARGET_REV),),
			)
		con.commit()
	finally:
		con.close()
	return out


def main() -> int:
	if len(sys.argv) < 2:
		print("usage: sqlite_upgrade_save.py save.sqlite [out_dir]", file=sys.stderr)
		return 1
	out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else None
	ready = upgrade(Path(sys.argv[1]), out_dir)
	print(str(ready))
	return 0


if __name__ == "__main__":
	sys.exit(main())
