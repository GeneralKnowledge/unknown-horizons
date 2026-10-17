#!/usr/bin/env python3
"""Probe all in-repo legacy .sqlite save fixtures for Godot load readiness."""

from __future__ import annotations

import bz2
import json
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
GODOT_ROOT = REPO_ROOT / "godot"
REPORT_DIR = REPO_ROOT / "development" / "godot" / "reports"
REPORT_PATH = REPORT_DIR / "sqlite_fixture_report.json"
FIXTURE_LIST = GODOT_ROOT / "resources" / "fixtures" / "sqlite_save_fixtures.json"
EXTRACT_SCRIPT = REPO_ROOT / "development" / "godot" / "sqlite_extract_buildings.py"
COMMUNITY_DIR = REPO_ROOT / "development" / "godot" / "fixtures" / "saves"


def discover_fixtures() -> list[Path]:
	paths: list[Path] = []
	for pattern in ("tests/game/fixtures/*.sqlite*", "tests/gui/**/fixtures/*.sqlite*"):
		paths.extend(LEGACY_ROOT.glob(pattern))
	if COMMUNITY_DIR.is_dir():
		paths.extend(COMMUNITY_DIR.glob("**/*.sqlite*"))
	seen: set[Path] = set()
	out: list[Path] = []
	for p in sorted(paths):
		rp = p.resolve()
		if rp in seen:
			continue
		seen.add(rp)
		out.append(rp)
	return out


def resolve_sqlite_path(path: Path) -> tuple[Path, tempfile.TemporaryDirectory | None]:
	if path.suffix == ".bz2" and path.name.endswith(".sqlite.bz2"):
		tmp = tempfile.TemporaryDirectory(prefix="uh-save-")
		out = Path(tmp.name) / path.name.replace(".bz2", "")
		with bz2.open(path, "rb") as src, out.open("wb") as dst:
			shutil.copyfileobj(src, dst)
		return out, tmp
	return path, None


def load_building_id_map() -> dict[int, str]:
	constants = json.loads((GODOT_ROOT / "resources/exported/constants.json").read_text())
	buildings = json.loads((GODOT_ROOT / "resources/exported/buildings.json").read_text())
	id_to_stem: dict[int, str] = {}
	for stem, data in buildings.items():
		id_name = str(data.get("id_name", ""))
		if not id_name.startswith("BUILDINGS."):
			continue
		key = id_name.split(".", 1)[1]
		bid = constants.get("BUILDINGS", {}).get(key)
		if bid is not None:
			id_to_stem[int(bid)] = stem
	return id_to_stem


def probe_fixture(path: Path, id_to_stem: dict[int, str]) -> dict:
	row: dict = {"path": str(path.relative_to(REPO_ROOT)), "ok": False, "errors": []}
	if not path.is_file():
		row["errors"].append("missing_file")
		return row

	sqlite_path, tmp = resolve_sqlite_path(path)
	try:
		header = sqlite_path.read_bytes()[:16]
		if not header.startswith(b"SQLite format 3"):
			row["errors"].append("not_sqlite")
			return row

		con = sqlite3.connect(str(sqlite_path))
		try:
			tables = {
				r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")
			}
			row["table_count"] = len(tables)
			for req in ("metadata", "building"):
				if req not in tables:
					row["errors"].append(f"missing_table:{req}")

			if "metadata" in tables:
				meta = {
					r[0]: r[1]
					for r in con.execute("SELECT name, value FROM metadata")
				}
				row["savegamerev"] = meta.get("savegamerev")
				row["map_name"] = meta.get("map_name")

			building_count = 0
			type_ids: set[int] = set()
			if "building" in tables:
				building_count = con.execute("SELECT COUNT(*) FROM building").fetchone()[0]
				type_ids = {int(r[0]) for r in con.execute("SELECT DISTINCT type FROM building")}
			row["building_count"] = building_count
			row["building_type_ids"] = sorted(type_ids)

			unknown = [tid for tid in type_ids if tid not in id_to_stem]
			row["unknown_building_type_ids"] = unknown
			row["known_building_types"] = len(type_ids) - len(unknown)

			if "storage" in tables:
				row["storage_rows"] = con.execute("SELECT COUNT(*) FROM storage").fetchone()[0]
			if "unit" in tables:
				row["unit_rows"] = con.execute("SELECT COUNT(*) FROM unit").fetchone()[0]
		finally:
			con.close()

		with tempfile.TemporaryDirectory(prefix="uh-extract-") as td:
			out_json = Path(td) / "buildings.json"
			limit = "2000" if "large" in path.name else "500"
			proc = subprocess.run(
				[sys.executable, str(EXTRACT_SCRIPT), str(sqlite_path), str(out_json), limit],
				capture_output=True,
				text=True,
			)
			row["extract_exit_code"] = proc.returncode
			if proc.returncode != 0:
				row["errors"].append("extract_failed")
				row["extract_stderr"] = proc.stderr.strip()[-500:]
			elif out_json.is_file():
				extracted = json.loads(out_json.read_text())
				row["extracted_buildings"] = len(
					[e for e in extracted if isinstance(e, dict) and not e.get("_skipped")]
				)

		row["ok"] = not row["errors"]
		return row
	finally:
		if tmp is not None:
			tmp.cleanup()


def main() -> int:
	if not (GODOT_ROOT / "resources/exported/constants.json").is_file():
		print("Run export_content.py first", file=sys.stderr)
		return 1

	id_to_stem = load_building_id_map()
	fixtures = discover_fixtures()
	rows = [probe_fixture(p, id_to_stem) for p in fixtures]

	REPORT_DIR.mkdir(parents=True, exist_ok=True)
	report = {
		"fixture_count": len(rows),
		"ok_count": sum(1 for r in rows if r.get("ok")),
		"fixtures": rows,
	}
	REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {REPORT_PATH} ({report['ok_count']}/{report['fixture_count']} ok)")

	# Godot GUT helper list (repo-relative paths for desktop load tests)
	list_paths = [r["path"] for r in rows if r.get("ok")]
	FIXTURE_LIST.parent.mkdir(parents=True, exist_ok=True)
	FIXTURE_LIST.write_text(json.dumps(list_paths, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {FIXTURE_LIST} ({len(list_paths)} paths)")

	failed = [r for r in rows if not r.get("ok")]
	if failed:
		for f in failed:
			print(f"FAIL {f['path']}: {f.get('errors')}", file=sys.stderr)
		return 1
	return 0


if __name__ == "__main__":
	sys.exit(main())
