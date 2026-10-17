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
		return out
	if path.suffix == ".sqlite":
		return path
	raise ValueError(f"Not a legacy save sqlite: {path}")


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
