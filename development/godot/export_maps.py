#!/usr/bin/env python3
"""Export legacy map .sqlite ground tiles to Godot MapLoader JSON."""

from __future__ import annotations

import json
import re
import sqlite3
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
MAPS_SRC = LEGACY_ROOT / "content" / "maps"
OUT_DIR = REPO_ROOT / "godot" / "resources" / "maps" / "ground"
MANIFEST_PATH = REPO_ROOT / "godot" / "resources" / "maps" / "maps_manifest.json"

# legacy horizons.constants.GROUND numeric ids → SimGround.Kind (godot/scripts/sim/world/sim_ground.gd)
# Kind: LAND=0, SHALLOW_WATER=1, DEEP_WATER=2
LEGACY_GROUND_TO_KIND = {
	0: 2,  # WATER
	1: 1,  # SHALLOW_WATER
	2: 1,  # deep-water transition tiles (coast)
	3: 0,  # DEFAULT_LAND
	4: 0,  # sand transition (buildable land)
	5: 1,  # coast grass/shallow
	6: 0,  # SAND
}

DEFAULT_EXPORT_MAPS = (
	"test-map-tiny.sqlite",
	"development.sqlite",
	"quattro.sqlite",
)


def map_id_from_filename(name: str) -> str:
	stem = name.replace(".sqlite", "")
	return re.sub(r"[^a-z0-9]+", "_", stem.lower()).strip("_")


def export_map_sqlite(path: Path) -> dict:
	con = sqlite3.connect(str(path))
	try:
		rows = con.execute("SELECT x, y, ground_id FROM ground").fetchall()
	finally:
		con.close()
	tiles: list[list[int]] = []
	for x, y, ground_id in rows:
		kind = LEGACY_GROUND_TO_KIND.get(int(ground_id), 2)
		tiles.append([int(x), int(y), kind])
	return {
		"format": 1,
		"source": str(path.relative_to(REPO_ROOT)),
		"tile_count": len(tiles),
		"tiles": tiles,
	}


def load_manifest() -> dict:
	if MANIFEST_PATH.is_file():
		return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
	return {"maps": []}


def upsert_manifest_entry(manifest: dict, map_id: str, name: str) -> None:
	maps: list = manifest.setdefault("maps", [])
	for entry in maps:
		if entry.get("id") == map_id:
			entry["name"] = name
			entry["loader"] = "ground_json"
			entry["ground"] = f"res://resources/maps/ground/{map_id}.json"
			return
	maps.append(
		{
			"id": map_id,
			"name": name,
			"loader": "ground_json",
			"ground": f"res://resources/maps/ground/{map_id}.json",
		}
	)


def main() -> int:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	manifest = load_manifest()
	exported = 0
	for filename in DEFAULT_EXPORT_MAPS:
		src = MAPS_SRC / filename
		if not src.is_file():
			print(f"skip missing map {src}")
			continue
		map_id = map_id_from_filename(filename)
		payload = export_map_sqlite(src)
		out_path = OUT_DIR / f"{map_id}.json"
		out_path.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
		display = filename.replace(".sqlite", "").replace("-", " ").title()
		upsert_manifest_entry(manifest, map_id, display)
		print(f"Wrote {out_path} ({payload['tile_count']} tiles)")
		exported += 1

	# Keep existing stub entries
	for entry in manifest.get("maps", []):
		if entry.get("loader") == "stub_test_island":
			continue
	manifest["maps"] = manifest.get("maps", [])
	MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"Updated {MANIFEST_PATH} ({exported} ground maps)")
	return 0 if exported > 0 else 1


if __name__ == "__main__":
	raise SystemExit(main())
