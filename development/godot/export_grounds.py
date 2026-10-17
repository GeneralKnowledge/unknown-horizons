#!/usr/bin/env python3
"""Export legacy GROUND tile id metadata for MapLoader / coast rules."""

from __future__ import annotations

import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CONSTANTS_PY = REPO_ROOT / "legacy" / "horizons" / "constants.py"
OUT = REPO_ROOT / "godot" / "resources" / "exported" / "grounds.json"

# Same mapping as export_maps.py → SimGround.Kind
LEGACY_GROUND_TO_KIND = {
	0: 2,
	1: 1,
	2: 1,
	3: 0,
	4: 0,
	5: 1,
	6: 0,
}


def parse_ground_class() -> dict:
	text = CONSTANTS_PY.read_text(encoding="utf-8")
	entries: dict[str, list] = {}
	current = None
	for line in text.splitlines():
		m = re.match(r"^\t([A-Z_0-9]+)\s*=\s*\((.*)\)\s*$", line)
		if not m:
			if line.startswith("class GROUND:"):
				current = "GROUND"
				continue
			if line.startswith("class ") and current == "GROUND":
				break
			continue
		name, inner = m.group(1), m.group(2)
		parts = [p.strip().strip('"') for p in inner.split(",")]
		if not parts:
			continue
		try:
			gid = int(parts[0])
		except ValueError:
			continue
		entries[name] = {
			"ground_id": gid,
			"sim_kind": LEGACY_GROUND_TO_KIND.get(gid, 2),
			"action_id": parts[1] if len(parts) > 1 else "straight",
			"rotation": int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 45,
		}
	return entries


def main() -> int:
	payload = {
		"legacy_to_sim_kind": LEGACY_GROUND_TO_KIND,
		"tiles": parse_ground_class(),
	}
	OUT.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	print(f"Wrote {OUT} ({len(payload['tiles'])} named tiles)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
