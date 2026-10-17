#!/usr/bin/env python3
"""Export legacy gui_buildmenu YAML to Godot build_menu.json."""

from __future__ import annotations

import json
import re
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
OUT = REPO_ROOT / "godot" / "resources" / "exported" / "build_menu.json"
MENU_DIR = LEGACY_ROOT / "content" / "objects" / "gui_buildmenu"
BUILDINGS_JSON = REPO_ROOT / "godot" / "resources" / "exported" / "buildings.json"
CONSTANTS_JSON = REPO_ROOT / "godot" / "resources" / "exported" / "constants.json"


def _id_to_stem(buildings: dict, constants: dict, token: str) -> str | None:
	if not token.startswith("BUILDINGS."):
		return None
	key = token.split(".", 1)[1]
	bid = constants.get("BUILDINGS", {}).get(key)
	if bid is None:
		return None
	for stem, data in buildings.items():
		if data.get("id_name") == token:
			return stem
		id_name = str(data.get("id_name", ""))
		if id_name.startswith("BUILDINGS."):
			k = id_name.split(".", 1)[1]
			if constants.get("BUILDINGS", {}).get(k) == bid:
				return stem
	return None


def _parse_tier_file(path: Path, buildings: dict, constants: dict) -> dict:
	data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
	tabs: list = []
	for tab_key, tab_val in data.items():
		if not isinstance(tab_val, list):
			continue
		icon = ""
		sections: list = []
		current_section: dict | None = None
		for item in tab_val:
			if isinstance(item, dict) and "icon" in item:
				icon = str(item["icon"])
				continue
			if isinstance(item, str) and item.startswith("_"):
				if current_section:
					sections.append(current_section)
				current_section = {"label": item[1:].strip(), "stems": []}
				continue
			if isinstance(item, str) and item.startswith("BUILDINGS."):
				stem = _id_to_stem(buildings, constants, item)
				if stem and current_section is not None:
					current_section["stems"].append(stem)
		if current_section:
			sections.append(current_section)
		tabs.append({"id": tab_key, "icon": icon, "sections": sections})
	return {"tabs": tabs}


def main() -> int:
	buildings = json.loads(BUILDINGS_JSON.read_text(encoding="utf-8"))
	constants = json.loads(CONSTANTS_JSON.read_text(encoding="utf-8"))
	tier = _parse_tier_file(MENU_DIR / "build_menu_per_tier.yaml", buildings, constants)
	OUT.write_text(json.dumps(tier, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	print(f"Wrote {OUT} ({len(tier['tabs'])} tabs)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
