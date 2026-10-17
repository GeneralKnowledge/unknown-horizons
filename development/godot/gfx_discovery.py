"""Discover legacy building actionset PNG paths for Godot gfx export."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
CONTENT_GFX = LEGACY_ROOT / "content" / "gfx"
BUILDINGS_YAML = LEGACY_ROOT / "content" / "objects" / "buildings"

TIER_PREF = (
	"TIER.SAILORS",
	"TIER.PIONEERS",
	"TIER.CITIZENS",
	"TIER.MERCHANTS",
	"TIER.ENTREPRENEURS",
)

IDLE_ACTION_CANDIDATES = ("idle", "idle_full", "default")
SKIP_WORKING_ACTIONS = frozenset(
	{"idle", "idle_full", "default", "build", "construct", "deconstruct", "destroy", "ruined"}
)


def _pick_png(action_dir: Path, rotation: int = 135) -> Path | None:
	if not action_dir.is_dir():
		return None
	rot_dir = action_dir / str(rotation)
	if not rot_dir.is_dir():
		rot_dirs = sorted(
			(r for r in action_dir.iterdir() if r.is_dir() and r.name.isdigit()),
			key=lambda p: int(p.name),
		)
		rot_dir = rot_dirs[0] if rot_dirs else None
	if rot_dir is None or not rot_dir.is_dir():
		return None
	pngs = sorted(rot_dir.glob("*.png"))
	return pngs[0] if pngs else None


def _find_actionset_dirs(as_name: str) -> list[Path]:
	return [m for m in CONTENT_GFX.rglob(as_name) if m.is_dir() and m.name == as_name]


def _pick_actionset_name(data: dict[str, Any]) -> str | None:
	acts = data.get("actionsets") or {}
	if not acts:
		return None
	for tier in TIER_PREF:
		if tier not in acts:
			continue
		name = _first_actionset_in_tier(acts[tier])
		if name:
			return name
	for tier_val in acts.values():
		name = _first_actionset_in_tier(tier_val)
		if name:
			return name
	return None


def _first_actionset_in_tier(tier_val: Any) -> str | None:
	if isinstance(tier_val, dict):
		for key in tier_val:
			if str(key).startswith("as_"):
				return str(key)
	elif isinstance(tier_val, list):
		for key in tier_val:
			if str(key).startswith("as_"):
				return str(key)
	return None


def _working_action_from_overlays(data: dict[str, Any], as_name: str) -> str | None:
	for comp in data.get("components") or []:
		if not isinstance(comp, dict):
			continue
		for key, val in comp.items():
			if key != "InventoryOverlayComponent" or not isinstance(val, dict):
				continue
			overlays = val.get("overlays") or {}
			block = overlays.get(as_name) or {}
			idle_map = block.get("idle") or {}
			for steps in idle_map.values():
				if not isinstance(steps, list):
					continue
				for step in steps:
					if isinstance(step, (list, tuple)) and len(step) >= 2 and step[1]:
						action = str(step[1])
						if action.lower() != "null":
							return action
	return None


def _pick_idle_action_dir(as_dir: Path) -> tuple[str | None, Path | None]:
	for name in IDLE_ACTION_CANDIDATES:
		png = _pick_png(as_dir / name)
		if png:
			return name, png
	for sub in sorted(as_dir.iterdir()):
		if not sub.is_dir():
			continue
		png = _pick_png(sub)
		if png:
			return sub.name, png
	return None, None


def _pick_working_png(as_dir: Path, as_name: str, data: dict[str, Any]) -> tuple[str | None, Path | None]:
	hint = _working_action_from_overlays(data, as_name)
	if hint:
		png = _pick_png(as_dir / hint)
		if png:
			return hint, png
	for sub in sorted(as_dir.iterdir()):
		if not sub.is_dir() or sub.name in SKIP_WORKING_ACTIONS:
			continue
		png = _pick_png(sub)
		if png:
			return sub.name, png
	return None, None


def _yaml_for_stem(stem: str) -> Path | None:
	candidates = (
		BUILDINGS_YAML / f"{stem}.yaml",
		BUILDINGS_YAML / "fields" / f"{stem}.yaml",
	)
	for path in candidates:
		if path.is_file():
			return path
	return None


def discover_building_gfx(stem: str) -> dict[str, Any]:
	"""Return discovery record with idle/working paths relative to CONTENT_GFX."""
	ypath = _yaml_for_stem(stem)
	if ypath is None:
		return {"stem": stem, "ok": False, "error": "no_yaml"}

	data = yaml.safe_load(ypath.read_text(encoding="utf-8")) or {}
	as_name = _pick_actionset_name(data)
	if not as_name:
		return {"stem": stem, "ok": False, "error": "no_actionset"}

	dirs = _find_actionset_dirs(as_name)
	if not dirs:
		return {"stem": stem, "ok": False, "error": "no_gfx_dir", "actionset": as_name}

	as_dir = min(dirs, key=lambda p: len(str(p)))
	idle_action, idle_png = _pick_idle_action_dir(as_dir)
	work_action, work_png = _pick_working_png(as_dir, as_name, data)
	if work_png is None and idle_png is not None:
		work_png = idle_png
		work_action = idle_action or "idle"

	def rel(p: Path | None) -> str | None:
		return str(p.relative_to(CONTENT_GFX)).replace("\\", "/") if p else None

	ok = idle_png is not None
	return {
		"stem": stem,
		"ok": ok,
		"actionset": as_name,
		"actionset_dir": str(as_dir.relative_to(LEGACY_ROOT / "content")).replace("\\", "/"),
		"idle_action": idle_action,
		"working_action": work_action,
		"idle": rel(idle_png),
		"working": rel(work_png),
	}


def discover_all_building_stems(stems: list[str]) -> tuple[dict[str, dict[str, str]], list[dict[str, Any]]]:
	"""Returns (gfx_map for export, full report rows).

	Paths in gfx_map are relative to ``legacy/content/gfx/`` (same as discovery ``idle``/``working`` fields).
	"""
	gfx_map: dict[str, dict[str, str]] = {}
	report: list[dict[str, Any]] = []
	for stem in stems:
		row = discover_building_gfx(stem)
		report.append(row)
		if not row.get("ok"):
			continue
		idle = row.get("idle")
		if not idle:
			continue
		working = row.get("working") or idle
		gfx_map[stem] = {"idle": str(idle), "working": str(working)}
	return gfx_map, report
