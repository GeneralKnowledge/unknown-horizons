#!/usr/bin/env python3
"""Build a single JSON extract bundle for Godot web / offline SQLite import."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


def _load_module(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return mod


def build_bundle(sqlite_path: Path, building_limit: int = 0) -> dict:
	root = Path(__file__).resolve().parent
	buildings_mod = _load_module("sqlite_extract_buildings", root / "sqlite_extract_buildings.py")
	storage_mod = _load_module("sqlite_extract_storage", root / "sqlite_extract_storage.py")
	units_mod = _load_module("sqlite_extract_units", root / "sqlite_extract_units.py")
	session_mod = _load_module("sqlite_extract_session", root / "sqlite_extract_session.py")
	settlement_mod = _load_module("sqlite_extract_settlement", root / "sqlite_extract_settlement.py")
	production_mod = _load_module("sqlite_extract_production", root / "sqlite_extract_production.py")
	metadata_mod = _load_module("sqlite_extract_metadata", root / "sqlite_extract_metadata.py")
	jobs_mod = _load_module("sqlite_extract_collector_jobs", root / "sqlite_extract_collector_jobs.py")
	settler_mod = _load_module("sqlite_extract_settler", root / "sqlite_extract_settler.py")
	limit = building_limit if building_limit > 0 else 500000
	return {
		"bundle_version": 1,
		"source_hint": sqlite_path.name,
		"buildings": buildings_mod.extract(sqlite_path, limit=limit, include_skipped=False),
		"storage": storage_mod.extract(sqlite_path, limit=5000),
		"units": units_mod.extract(sqlite_path, limit=5000),
		"session": session_mod.extract(sqlite_path),
		"settlements": settlement_mod.extract(sqlite_path),
		"settler_buildings": settler_mod.extract(sqlite_path),
		"production": production_mod.extract(sqlite_path, limit=10000),
		"metadata": metadata_mod.extract(sqlite_path),
		"collector_jobs": jobs_mod.extract(sqlite_path),
	}


def main() -> int:
	if len(sys.argv) < 3:
		print("usage: sqlite_extract_bundle.py save.sqlite out.extract.json", file=sys.stderr)
		return 1
	path = Path(sys.argv[1])
	out = Path(sys.argv[2])
	limit = int(sys.argv[3]) if len(sys.argv) > 3 else 0
	out.write_text(json.dumps(build_bundle(path, limit), indent=2) + "\n", encoding="utf-8")
	print("Wrote %s" % out)
	return 0


if __name__ == "__main__":
	sys.exit(main())
