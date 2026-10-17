#!/usr/bin/env python3
"""Export placeholder building gfx manifests for the Godot port (DLC vertical slice)."""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GODOT_ROOT = REPO_ROOT / "godot"


def _png_chunk(tag: bytes, data: bytes) -> bytes:
	return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_solid_png(path: Path, width: int, height: int, rgba: tuple[int, int, int, int]) -> None:
	"""Minimal RGBA PNG writer (stdlib only)."""
	raw_rows = []
	for _y in range(height):
		row = bytes([0])  # filter type 0
		for _x in range(width):
			row += bytes(rgba)
		raw_rows.append(row)
	compressed = zlib.compress(b"".join(raw_rows), 9)
	ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
	png = b"\x89PNG\r\n\x1a\n"
	png += _png_chunk(b"IHDR", ihdr)
	png += _png_chunk(b"IDAT", compressed)
	png += _png_chunk(b"IEND", b"")
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_bytes(png)


def export_lumberjack_slice() -> None:
	out_dir = GODOT_ROOT / "resources" / "gfx" / "lumberjackcamp"
	write_solid_png(out_dir / "idle.png", 64, 64, (140, 100, 60, 255))
	write_solid_png(out_dir / "working.png", 64, 64, (180, 120, 40, 255))
	manifest = {
		"building_stem": "lumberjackcamp",
		"building_id": int(
			json.loads((GODOT_ROOT / "resources" / "exported" / "constants.json").read_text())[
				"BUILDINGS"
			]["LUMBERJACK"]
		),
		"animations": {
			"idle": {"texture": "idle.png", "fps": 1.0},
			"working": {"texture": "working.png", "fps": 4.0},
		},
	}
	(out_dir / "sprite_manifest.json").write_text(
		json.dumps(manifest, indent=2), encoding="utf-8"
	)
	print(f"Wrote lumberjack gfx manifest to {out_dir}")


def export_dlc_gfx() -> None:
	pack = GODOT_ROOT / "resources" / "dlc" / "northern_company" / "gfx"
	write_solid_png(pack / "faction_accent.png", 32, 32, (74, 124, 158, 255))
	manifest = {
		"pack_id": "northern_company",
		"building_tints": {
			"northern_warehouse": [0.55, 0.75, 0.95, 1.0],
			"northern_smokery": [0.5, 0.65, 0.85, 1.0],
		},
	}
	(pack / "sprite_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
	print(f"Wrote DLC gfx manifest to {pack}")


def main() -> int:
	export_lumberjack_slice()
	export_dlc_gfx()
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
