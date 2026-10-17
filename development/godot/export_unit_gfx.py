#!/usr/bin/env python3
"""Export unit/ship gfx slices (idle frame) for Godot view layer."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
GODOT_ROOT = REPO_ROOT / "godot"
GFX_ROOT = LEGACY_ROOT / "content" / "gfx"
UNITS_YAML = LEGACY_ROOT / "content" / "objects" / "units"
OUT_ROOT = GODOT_ROOT / "resources" / "gfx" / "units"


def _pick_actionset(data: dict) -> str | None:
	acts = data.get("actionsets") or {}
	if isinstance(acts, dict):
		for val in acts.values():
			if isinstance(val, dict):
				for key in val:
					if str(key).startswith("as_"):
						return str(key)
			elif isinstance(val, list):
				for key in val:
					if str(key).startswith("as_"):
						return str(key)
	return None


def _find_as_dir(as_name: str) -> Path | None:
	matches = [p for p in GFX_ROOT.rglob(as_name) if p.is_dir() and p.name == as_name]
	return min(matches, key=lambda p: len(str(p))) if matches else None


def _idle_png(as_dir: Path) -> Path | None:
	for sub in ("idle", "idle_full", "default"):
		candidate = as_dir / sub / "135"
		if candidate.is_dir():
			pngs = sorted(candidate.glob("*.png"))
			if pngs:
				return pngs[0]
	for sub in sorted(as_dir.iterdir()):
		if sub.is_dir():
			candidate = sub / "135"
			if candidate.is_dir():
				pngs = sorted(candidate.glob("*.png"))
				if pngs:
					return pngs[0]
	return None


def export_unit(stem: str, yaml_path: Path) -> bool:
	data = yaml.safe_load(yaml_path.read_text(encoding="utf-8")) or {}
	as_name = _pick_actionset(data)
	if not as_name:
		return False
	as_dir = _find_as_dir(as_name)
	if as_dir is None:
		return False
	src = _idle_png(as_dir)
	if src is None:
		return False
	out_dir = OUT_ROOT / stem
	out_dir.mkdir(parents=True, exist_ok=True)
	shutil.copy2(src, out_dir / "idle.png")
	manifest = {
		"unit_stem": stem,
		"actionset": as_name,
		"source": "legacy_png",
		"animations": {"idle": {"texture": "idle.png", "fps": 1.0}},
	}
	(out_dir / "sprite_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
	return True


def main() -> int:
	OUT_ROOT.mkdir(parents=True, exist_ok=True)
	ok = 0
	for path in sorted(UNITS_YAML.rglob("*.yaml")):
		stem = path.stem
		if export_unit(stem, path):
			ok += 1
			print(f"Wrote unit gfx {stem}")
	index = {"units": sorted(p.name for p in OUT_ROOT.iterdir() if p.is_dir())}
	(OUT_ROOT / "index.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
	print(f"Unit gfx export: {ok} stems → {OUT_ROOT}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
