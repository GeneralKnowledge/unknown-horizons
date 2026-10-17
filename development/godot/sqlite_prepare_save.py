#!/usr/bin/env python3
"""Resolve a legacy save path (.sqlite or .sqlite.bz2) to a readable SQLite file."""

from __future__ import annotations

import bz2
import shutil
import sys
import tempfile
from pathlib import Path


def prepare(path: Path, out_dir: Path | None = None) -> Path:
	path = path.resolve()
	if not path.is_file():
		raise FileNotFoundError(path)
	if path.name.endswith(".sqlite.bz2"):
		dest_dir = out_dir or Path(tempfile.mkdtemp(prefix="uh-save-"))
		dest_dir.mkdir(parents=True, exist_ok=True)
		out = dest_dir / path.name.replace(".bz2", "")
		with bz2.open(path, "rb") as src, out.open("wb") as dst:
			shutil.copyfileobj(src, dst)
		return _maybe_upgrade(out, out_dir)
	if path.suffix == ".sqlite":
		upgraded = _maybe_upgrade(path, out_dir)
		return upgraded
	raise ValueError(f"Not a legacy save sqlite: {path}")


def _maybe_upgrade(path: Path, out_dir: Path | None) -> Path:
	"""Run lightweight rev bump when savegamerev < 77."""
	import sqlite3

	con = sqlite3.connect(str(path))
	try:
		rev_row = con.execute(
			"SELECT value FROM metadata WHERE name='savegamerev'"
		).fetchone()
	finally:
		con.close()
	if not rev_row:
		return path
	rev = int(rev_row[0])
	if rev >= 77:
		return path
	upgrade_script = Path(__file__).resolve().parent / "sqlite_upgrade_save.py"
	if not upgrade_script.is_file():
		return path
	dest_dir = out_dir or Path(tempfile.mkdtemp(prefix="uh-upgraded-"))
	import subprocess
	import sys

	proc = subprocess.run(
		[sys.executable, str(upgrade_script), str(path), str(dest_dir)],
		capture_output=True,
		text=True,
	)
	if proc.returncode != 0:
		return path
	out = proc.stdout.strip().splitlines()[-1]
	return Path(out) if out else path


def main() -> int:
	if len(sys.argv) < 2:
		print("usage: sqlite_prepare_save.py save.sqlite[.bz2] [out_dir]", file=sys.stderr)
		return 1
	out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else None
	ready = prepare(Path(sys.argv[1]), out_dir)
	print(str(ready))
	return 0


if __name__ == "__main__":
	sys.exit(main())
