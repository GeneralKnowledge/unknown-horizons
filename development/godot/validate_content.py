#!/usr/bin/env python3
"""Validate exported Godot content (run after export_content.py)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
EXPORTED = REPO_ROOT / "godot" / "resources" / "exported"
GFX_MANIFEST_STEMS = {
	"lumberjackcamp",
	"hunterstent",
	"fishermanstent",
	"brickyard",
	"warehouse",
}


def load_json(name: str) -> dict:
	path = EXPORTED / name
	if not path.is_file():
		raise SystemExit(f"error: missing {path}")
	return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
	errors: list[str] = []
	warnings: list[str] = []

	constants = load_json("constants.json")
	res_map = constants.get("RES", {})
	res_ids = set(int(v) for v in res_map.values())
	building_ids = set(int(v) for v in constants.get("BUILDINGS", {}).values())

	def resolve_res_key(key) -> int | None:
		if isinstance(key, int):
			return key
		s = str(key)
		if s.isdigit():
			return int(s)
		if s.startswith("RES."):
			name = s[4:]
			if name in res_map:
				return int(res_map[name])
			errors.append(f"unknown RES token in export: {s}")
			return None
		errors.append(f"invalid resource key in export: {s!r}")
		return None

	buildings = load_json("buildings.json")
	stems_seen: dict[str, str] = {}

	for stem, export in buildings.items():
		if stem in stems_seen:
			errors.append(f"duplicate stem key: {stem}")
		stems_seen[stem] = stem
		id_name = export.get("id_name", "")
		components = export.get("components", {})

		storage = components.get("Storage", {})
		for slot_key in storage.get("config", {}).get("slot_sizes", {}).keys():
			rid = resolve_res_key(slot_key)
			if rid is not None and rid not in res_ids:
				errors.append(f"{stem}: Storage slot unknown resource id {rid}")

		producer = components.get("Producer", {})
		for _line_key, line in producer.get("productionlines", {}).items():
			for entry in line.get("consumes", []) + line.get("produces", []):
				if not entry:
					continue
				rid = resolve_res_key(entry[0])
				if rid is not None and rid not in res_ids:
					errors.append(f"{stem}: production references unknown resource id {rid}")

		collecting = components.get("Collecting", {})
		for collector_id in collecting.get("collectors", {}).keys():
			cid = int(collector_id)
			if cid not in building_ids and cid not in res_ids:
				warnings.append(f"{stem}: Collecting references id {cid} (not in RES/BUILDINGS export)")

	menu_path = EXPORTED / "poc_build_menu.json"
	if menu_path.is_file():
		menu = json.loads(menu_path.read_text(encoding="utf-8"))
		for stem in menu.get("stems", []):
			if stem not in buildings:
				errors.append(f"poc_build_menu stem not in buildings.json: {stem}")

	gfx_root = REPO_ROOT / "godot" / "resources" / "gfx"
	for stem in GFX_MANIFEST_STEMS:
		manifest = gfx_root / stem / "sprite_manifest.json"
		if not manifest.is_file():
			warnings.append(f"missing gfx manifest for {stem} (placeholder used at runtime)")

	for w in warnings:
		print(f"warning: {w}", file=sys.stderr)
	for e in errors:
		print(f"error: {e}", file=sys.stderr)

	if errors:
		print(f"validate_content: {len(errors)} error(s)", file=sys.stderr)
		return 1
	print(f"validate_content: OK ({len(buildings)} buildings)")
	return 0


if __name__ == "__main__":
	sys.exit(main())
