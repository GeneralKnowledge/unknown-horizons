#!/usr/bin/env python3
"""Run legacy Python sim on fire.sqlite for N ticks; emit inventory totals (M7 dual-run).

Exit code 2 when FIFE/legacy runtime is unavailable (CI skips GUT comparison).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LEGACY = REPO / "legacy"


def _inventory_totals(session) -> dict[str, int]:
	from horizons.component.storagecomponent import StorageComponent

	totals: dict[int, int] = {}
	settlement = session.world.player.settlements[0]
	st = settlement.get_component(StorageComponent)
	for res_id, amount in st.inventory.get_stored_resources().items():
		if int(amount) != 0:
			totals[int(res_id)] = totals.get(int(res_id), 0) + int(amount)
	for b in session.world.get_all_buildings():
		st = b.get_component(StorageComponent)
		if st is None:
			continue
		for res_id, amount in st.inventory.get_stored_resources().items():
			if int(amount) != 0:
				totals[int(res_id)] = totals.get(int(res_id), 0) + int(amount)
	return {str(k): v for k, v in sorted(totals.items())}


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("save", type=Path)
	parser.add_argument("out", type=Path)
	parser.add_argument("--ticks", type=int, default=128)
	args = parser.parse_args()

	if str(LEGACY) not in sys.path:
		sys.path.insert(0, str(LEGACY))

	try:
		import fife  # noqa: F401
	except ImportError:
		print("fife not installed", file=sys.stderr)
		return 2

	from horizons.scheduler import Scheduler
	from tests.game import load_session

	save = args.save.resolve()
	if not save.is_file():
		print("missing save", save, file=sys.stderr)
		return 1

	session = load_session(str(save))
	Scheduler().before_ticking()
	for _ in range(args.ticks):
		Scheduler().tick(Scheduler().cur_tick + 1)

	payload = {
		"fixture": save.name,
		"ticks": args.ticks,
		"scheduler_tick": int(Scheduler().cur_tick),
		"totals_by_resource_id": _inventory_totals(session),
	}
	args.out.parent.mkdir(parents=True, exist_ok=True)
	args.out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
	print("Wrote", args.out)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
