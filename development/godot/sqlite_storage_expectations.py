#!/usr/bin/env python3
"""Aggregate storage rows per building worldid for legacy save fixtures (T1 parity)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FIXTURE_LIST = REPO / "godot" / "resources" / "fixtures" / "sqlite_save_fixtures.json"
OUT_DIR = REPO / "godot" / "resources" / "fixtures" / "sqlite_storage"


def aggregate(rows: list[dict]) -> dict[str, dict[str, int]]:
	by_wid: dict[int, dict[int, int]] = {}
	for row in rows:
		wid = int(row["worldid"])
		res = int(row["resource_id"])
		amt = int(row["amount"])
		by_wid.setdefault(wid, {})
		by_wid[wid][res] = by_wid[wid].get(res, 0) + amt
	out: dict[str, dict[str, int]] = {}
	for wid, resources in sorted(by_wid.items()):
		out[str(wid)] = {str(k): v for k, v in sorted(resources.items()) if v != 0}
	return out


def main() -> int:
	sys.path.insert(0, str(REPO / "development" / "godot"))
	from sqlite_extract_storage import extract  # noqa: E402
	from sqlite_prepare_save import prepare  # noqa: E402

	paths: list[str] = []
	if FIXTURE_LIST.is_file():
		paths = json.loads(FIXTURE_LIST.read_text(encoding="utf-8"))
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	tmp_dir = OUT_DIR / "_prepare"
	tmp_dir.mkdir(parents=True, exist_ok=True)
	for rel in paths:
		p = Path(rel)
		if not p.is_absolute():
			p = REPO / p
		if not p.is_file():
			print("skip missing", p, file=sys.stderr)
			continue
		try:
			sqlite_path = prepare(p, tmp_dir)
		except (OSError, ValueError) as exc:
			print("skip unreadable", p, exc, file=sys.stderr)
			continue
		rows = extract(sqlite_path)
		payload = {
			"fixture": str(p.relative_to(REPO)),
			"storage_row_count": len(rows),
			"by_worldid": aggregate(rows),
		}
		name = p.name.replace(".sqlite.bz2", "").replace(".sqlite", "")
		out = OUT_DIR / f"{name}.json"
		out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
		print("Wrote", out, "(%s worldids)" % len(payload["by_worldid"]))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
