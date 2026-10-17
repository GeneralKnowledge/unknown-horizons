#!/usr/bin/env python3
"""Copy ambient OGG paths referenced in building/unit YAML into godot/resources/audio/."""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPO_ROOT / "legacy"
CONTENT = LEGACY_ROOT / "content"
OUT_DIR = REPO_ROOT / "godot" / "resources" / "audio" / "exported"
MANIFEST = OUT_DIR / "manifest.json"
OGG_RE = re.compile(r"[\w./-]+\.ogg", re.I)


def _scan_yaml(path: Path) -> set[str]:
	found: set[str] = set()
	try:
		text = path.read_text(encoding="utf-8")
	except OSError:
		return found
	for match in OGG_RE.findall(text):
		if "content/audio" in match or match.startswith("audio/"):
			found.add(match.replace("\\", "/"))
	return found


def main() -> int:
	paths: set[str] = set()
	for root in (
		CONTENT / "objects" / "buildings",
		CONTENT / "objects" / "units",
	):
		for ypath in root.rglob("*.yaml"):
			paths.update(_scan_yaml(ypath))
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	copied: dict[str, str] = {}
	for rel in sorted(paths):
		src = CONTENT / rel.replace("content/", "")
		if not src.is_file():
			alt = LEGACY_ROOT / rel
			src = alt if alt.is_file() else src
		if not src.is_file():
			continue
		name = src.name
		dst = OUT_DIR / name
		shutil.copy2(src, dst)
		copied[rel] = f"res://resources/audio/exported/{name}"
	MANIFEST.write_text(json.dumps({"files": copied}, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {len(copied)} audio files to {OUT_DIR}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
