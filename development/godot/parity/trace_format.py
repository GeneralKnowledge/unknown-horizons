"""Normalized parity trace helpers (legacy + Godot)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def normalize_trace(data: dict[str, Any]) -> dict[str, Any]:
	"""Sort buildings and resource keys for stable comparison."""
	out = {
		"scenario_id": data.get("scenario_id", ""),
		"engine": data.get("engine", ""),
		"tick": int(data.get("tick", 0)),
		"settlement_storage": _sort_res_map(data.get("settlement_storage", {})),
		"buildings": [],
	}
	buildings = list(data.get("buildings", []))
	for b in buildings:
		out["buildings"].append(
			{
				"stem": str(b.get("stem", "")),
				"x": int(b.get("x", 0)),
				"y": int(b.get("y", 0)),
				"storage": _sort_res_map(b.get("storage", {})),
				"producer_active": bool(b.get("producer_active", True)),
			}
		)
	out["buildings"].sort(key=lambda b: (b["stem"], b["x"], b["y"]))
	return out


def _sort_res_map(raw: dict) -> dict[str, int]:
	out: dict[str, int] = {}
	for key, val in raw.items():
		out[str(key)] = int(val)
	return dict(sorted(out.items()))


def load_trace(path: Path) -> dict[str, Any]:
	return normalize_trace(json.loads(path.read_text(encoding="utf-8")))


def write_trace(path: Path, data: dict[str, Any]) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text(json.dumps(normalize_trace(data), indent=2, sort_keys=True), encoding="utf-8")
