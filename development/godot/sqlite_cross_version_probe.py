#!/usr/bin/env python3
"""Probe a legacy save via Python extracts (cross-check Godot SqliteSaveLoader metrics)."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


def _load(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return mod


def probe(sqlite_path: Path) -> dict:
	root = Path(__file__).resolve().parent
	buildings = _load("b", root / "sqlite_extract_buildings.py").extract(sqlite_path, limit=0)
	storage = _load("s", root / "sqlite_extract_storage.py").extract(sqlite_path, limit=5000)
	units = _load("u", root / "sqlite_extract_units.py").extract(sqlite_path, limit=5000)
	from collections import Counter

	unit_kinds = Counter(r.get("kind", "unit") for r in units)
	building_rows = [r for r in buildings if not r.get("_skipped")]
	return {
		"buildings_extracted": len(building_rows),
		"storage_rows": len(storage),
		"unit_rows": len(units),
		"unit_kinds": dict(unit_kinds),
		"collector_rows": unit_kinds.get("collector", 0),
		"wild_animal_rows": unit_kinds.get("wild_animal", 0),
		"ship_rows": unit_kinds.get("ship", 0),
		"legacy_unit_rows": unit_kinds.get("unit", 0),
	}


def main() -> int:
	if len(sys.argv) < 2:
		print("usage: sqlite_cross_version_probe.py save.sqlite [out.json]", file=sys.stderr)
		return 1
	path = Path(sys.argv[1])
	data = probe(path)
	if len(sys.argv) >= 3:
		Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	else:
		print(json.dumps(data, indent=2))
	return 0


if __name__ == "__main__":
	sys.exit(main())
