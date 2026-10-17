#!/usr/bin/env python3
"""Write godot/resources/export_manifest.json after export steps."""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GODOT = REPO_ROOT / "godot"
MANIFEST = GODOT / "resources" / "export_manifest.json"


def main() -> int:
	failures = sys.argv[1:] if len(sys.argv) > 1 else []
	buildings = json.loads((GODOT / "resources/exported/buildings.json").read_text())
	gfx_index = json.loads((GODOT / "resources/gfx/index.json").read_text())
	data = {
		"generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
		"steps": [
			"export_content.py",
			"export_gfx.py --auto",
			"validate_content.py",
		],
		"counts": {
			"buildings_exported": len(buildings),
			"gfx_manifest_stems": len(gfx_index.get("buildings", {})),
		},
		"paths": {
			"exported_dir": "godot/resources/exported",
			"gfx_index": "godot/resources/gfx/index.json",
			"gfx_report": "godot/resources/gfx/export_report.json",
		},
		"failures": failures,
	}
	MANIFEST.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {MANIFEST}")
	return 1 if failures else 0


if __name__ == "__main__":
	raise SystemExit(main())
