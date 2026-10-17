#!/usr/bin/env python3
"""Run a parity scenario on legacy Horizons (Python sim) and emit trace_legacy.json."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
LEGACY_ROOT = REPO_ROOT / "legacy"
PARITY_DIR = Path(__file__).resolve().parent

if str(LEGACY_ROOT) not in sys.path:
	sys.path.insert(0, str(LEGACY_ROOT))

try:
	import fife  # noqa: F401
except ImportError:
	print(
		"legacy parity skipped: Python module 'fife' not installed "
		"(install Unknown Horizons runtime deps to compare against legacy sim)",
		file=sys.stderr,
	)
	sys.exit(2)

from development.godot.parity.trace_format import write_trace  # noqa: E402

from horizons.command.building import Build  # noqa: E402
from horizons.component.storagecomponent import StorageComponent  # noqa: E402
from horizons.constants import BUILDINGS, RES  # noqa: E402
from horizons.util.shapes import Point  # noqa: E402
from horizons.world.production.producer import Producer  # noqa: E402
from tests.game import new_session  # noqa: E402
from tests.game.utils import create_map, new_settlement  # noqa: E402

RES_BY_ID = {v: k for k, v in vars(RES).items() if isinstance(v, int) and k.isupper()}
BUILDING_BY_ID = {v: k for k, v in vars(BUILDINGS).items() if isinstance(v, int) and k.isupper()}


def _load_map_specs() -> dict:
	return json.loads((PARITY_DIR / "map_specs.json").read_text(encoding="utf-8"))


def _stem_for_building_id(building_id: int) -> str:
	name = BUILDING_BY_ID.get(building_id, str(building_id))
	return name.lower()


def _storage_named(inv) -> dict[str, int]:
	out: dict[str, int] = {}
	for res_id, amount in inv.get_stored_resources().items():
		name = RES_BY_ID.get(int(res_id), str(res_id))
		if int(amount) != 0:
			out[name] = int(amount)
	return out


def _trace_from_session(session, scenario_id: str) -> dict:
	settlement = session.world.player.settlements[0]
	inv = settlement.get_component(StorageComponent).inventory
	buildings_out = []
	for b in session.world.get_all_buildings():
		st = b.get_component(StorageComponent)
		storage = _storage_named(st.inventory) if st else {}
		producer = b.get_component(Producer)
		active = producer.is_active() if producer else True
		buildings_out.append(
			{
				"stem": _stem_for_building_id(b.id),
				"x": b.position.x,
				"y": b.position.y,
				"storage": storage,
				"producer_active": active,
			}
		)
	from horizons.scheduler import Scheduler

	return {
		"scenario_id": scenario_id,
		"engine": "legacy",
		"tick": int(Scheduler().cur_tick),
		"settlement_storage": _storage_named(inv),
		"buildings": buildings_out,
	}


def _resolve_building(name: str) -> int:
	if not hasattr(BUILDINGS, name):
		raise KeyError("Unknown BUILDINGS.%s" % name)
	return int(getattr(BUILDINGS, name))


def _resolve_res(name: str) -> int:
	if not hasattr(RES, name):
		raise KeyError("Unknown RES.%s" % name)
	return int(getattr(RES, name))


def run_scenario(scenario_path: Path) -> dict:
	scenario = json.loads(scenario_path.read_text(encoding="utf-8"))
	scenario_id = str(scenario["id"])
	map_specs = _load_map_specs()
	spec = map_specs[str(scenario["map"])]
	settle_xy = spec["settlement"]["legacy"]

	session, player = new_session(mapgen=create_map)
	settlement, island = new_settlement(session, pos=Point(settle_xy[0], settle_xy[1]))
	start_res = spec.get("starting_resources", {})
	inv = settlement.get_component(StorageComponent).inventory
	for res_name, amount in start_res.items():
		inv.alter(_resolve_res(res_name), int(amount))

	last_building = None
	for step in scenario.get("steps", []):
		op = step["op"]
		if op == "settle":
			continue
		if op == "build":
			bid = _resolve_building(step["building"])
			last_building = Build(bid, int(step["x"]), int(step["y"]), island, settlement=settlement)(player)
		elif op == "build_ownerless":
			bid = _resolve_building(step["building"])
			last_building = Build(bid, int(step["x"]), int(step["y"]), island)(player)
		elif op == "alter_storage":
			target = step.get("target", "building")
			res_id = _resolve_res(step["resource"])
			amount = int(step["amount"])
			if target == "settlement":
				inv.alter(res_id, amount)
			else:
				assert last_building is not None
				last_building.get_component(StorageComponent).inventory.alter(res_id, amount)
		elif op == "run_ticks":
			session.run(ticks=int(step["ticks"]))
		elif op == "run_seconds":
			session.run(seconds=float(step["seconds"]))
		elif op == "toggle_producer":
			assert last_building is not None
			prod = last_building.get_component(Producer)
			if step.get("active") is False:
				prod.set_active(active=False)
			else:
				prod.toggle_active()
		else:
			raise NotImplementedError("legacy op %s" % op)

	return _trace_from_session(session, scenario_id)


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("scenario", type=Path)
	parser.add_argument("--out", type=Path, default=Path("/tmp/uh-parity/trace_legacy.json"))
	args = parser.parse_args()
	trace = run_scenario(args.scenario.resolve())
	write_trace(args.out, trace)
	print("Wrote %s" % args.out)
	return 0


if __name__ == "__main__":
	sys.exit(main())
