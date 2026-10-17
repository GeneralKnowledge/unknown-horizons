#!/usr/bin/env python3
"""Report pytest → GUT coverage matrix counts (Appendix C style)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

MATRIX: list[tuple[str, str | None, str]] = [
	("tests/unittests/test_scheduler.py", "godot/tests/unit/test_scheduler.gd", "scheduler"),
	("tests/unittests/test_timer.py", "godot/tests/unit/test_game_clock.gd", "timer"),
	("tests/unittests/world/test_storage.py", "godot/tests/unit/test_storage.gd", "storage"),
	(
		"tests/unittests/world/production/test_productionline.py",
		"godot/tests/unit/test_production_line.gd",
		"productionline",
	),
	("tests/game/test_production.py", "godot/tests/integration/test_wood_production.gd", "production"),
	(
		"tests/unittests/world/buildability/test_connectedareacache.py",
		"godot/tests/unit/test_connected_area_cache.gd",
		"connected_area",
	),
	(
		"tests/unittests/world/buildability/test_partialbinarycache.py",
		"godot/tests/unit/test_partial_binary_cache.gd",
		"partial_binary",
	),
	(
		"tests/unittests/world/units/collectors/test_collector.py",
		"godot/tests/unit/test_collector_job_list.gd",
		"collector",
	),
	("tests/unittests/util/test_shapes.py", "godot/tests/unit/test_shapes.gd", "shapes"),
	(
		"tests/unittests/util/test_tile_orientation.py",
		"godot/tests/unit/test_tile_orientation.gd",
		"tile_orientation",
	),
	(
		"tests/unittests/world/component/test_healthcomponent.py",
		None,
		"health",
	),
	(
		"tests/unittests/world/component/test_namedcomponent.py",
		None,
		"named",
	),
	(
		"tests/unittests/world/component/test_tradepostcomponent.py",
		None,
		"tradepost",
	),
	("tests/game/test_buildings.py", "godot/tests/integration/test_buildings", "buildings"),
	("tests/game/test_load_save.py", "godot/tests/integration/test_session_save.gd", "load_save"),
]


def count_pytest_tests(path: Path) -> int:
	if not path.is_file():
		return 0
	text = path.read_text(encoding="utf-8")
	return len(re.findall(r"^def test_", text, re.MULTILINE))


def count_gut_tests(path: Path) -> int:
	if path is None:
		return 0
	if path.is_file():
		text = path.read_text(encoding="utf-8")
		return len(re.findall(r"^func test_", text, re.MULTILINE))
	if not path.is_dir() and str(path).endswith("test_buildings"):
		# integration prefix: multiple wave files
		int_dir = REPO_ROOT / "godot/tests/integration"
		total = 0
		for pattern in ("test_buildings_*.gd",):
			for f in sorted(int_dir.glob(pattern)):
				total += count_gut_tests(f)
		return total
	return 0


def count_buildings_gut() -> int:
	int_dir = REPO_ROOT / "godot/tests/integration"
	total = 0
	for f in sorted(int_dir.glob("test_buildings*.gd")):
		total += count_gut_tests(f)
	return total


def main() -> int:
	print("pytest → GUT matrix (auto-counted)\n")
	print(f"{'Source':<55} {'GUT target':<45} {'Count'}")
	print("-" * 110)
	total_py = 0
	total_gut = 0
	for py_rel, gut_rel, _label in MATRIX:
		py_path = REPO_ROOT / py_rel
		py_n = count_pytest_tests(py_path)
		if _label == "buildings":
			gut_n = count_buildings_gut()
			gut_display = "integration/test_buildings_*.gd"
		elif gut_rel:
			gut_path = REPO_ROOT / gut_rel
			gut_n = count_gut_tests(gut_path)
			gut_display = gut_rel
		else:
			gut_n = 0
			gut_display = "—"
		total_py += py_n
		total_gut += min(gut_n, py_n) if py_n else gut_n
		status = f"{gut_n}/{py_n}" if py_n else str(gut_n)
		print(f"{py_rel:<55} {gut_display:<45} {status}")
	print("-" * 110)
	print(f"Tracked pytest cases (sum): {total_py}")
	print(f"GUT cases (buildings waves summed): {count_buildings_gut()} + other files above")
	return 0


if __name__ == "__main__":
	sys.exit(main())
