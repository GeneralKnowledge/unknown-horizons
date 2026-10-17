#!/usr/bin/env python3
"""Export building gfx manifests for the Godot port (legacy PNG + optional SQLite atlas probe)."""

from __future__ import annotations

import json
import shutil
import sqlite3
import struct
import zlib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GODOT_ROOT = REPO_ROOT / "godot"
CONTENT_GFX = REPO_ROOT / "content" / "gfx" / "buildings"

# building stem -> idle/working source PNG (135° view)
LEGACY_BUILDING_GFX: dict[str, dict[str, str]] = {
	"lumberjackcamp": {
		"idle": "sailors/lumberjack/as_lumberjack0/idle/135/0.png",
		"working": "sailors/lumberjack/as_lumberjack0/logs_1/135/0.png",
	},
	"hunterstent": {
		"idle": "sailors/hunter/as_hunter0/idle/135/0.png",
		"working": "sailors/hunter/as_hunter0/idle/135/0.png",
	},
	"fishermanstent": {
		"idle": "sailors/fisherman/as_fisherman0/idle/135/0.png",
		"working": "sailors/fisherman/as_fisherman0/idle/135/0.png",
	},
	"brickyard": {
		"idle": "pioneers/brickyard/as_brickyard0/idle/135/000.png",
		"working": "pioneers/brickyard/as_brickyard0/bricks_01/135/000.png",
	},
	"warehouse": {
		"idle": "sailors/warehouse/as_warehouse0/idle/135/0.png",
		"working": "sailors/warehouse/as_warehouse0/idle/135/0.png",
	},
}


def _png_chunk(tag: bytes, data: bytes) -> bytes:
	return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_solid_png(path: Path, width: int, height: int, rgba: tuple[int, int, int, int]) -> None:
	raw_rows = []
	for _y in range(height):
		row = bytes([0])
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


def find_sqlite_with_atlas_table() -> Path | None:
	candidates = [
		REPO_ROOT / "content" / "atlas.sql",
	]
	for pattern in ("**/*.sqlite", "**/*.sqlite.bz2"):
		for path in REPO_ROOT.glob(pattern):
			if "node_modules" in path.parts:
				continue
			candidates.append(path)
	for path in candidates:
		if not path.is_file() or path.suffix == ".bz2":
			continue
		try:
			con = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
			tables = {row[0] for row in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
			con.close()
			if "atlas" in tables:
				return path
		except sqlite3.Error:
			continue
	return None


def export_building_slice(stem: str, paths: dict[str, str]) -> None:
	constants = json.loads((GODOT_ROOT / "resources" / "exported" / "constants.json").read_text())
	buildings = json.loads((GODOT_ROOT / "resources" / "exported" / "buildings.json").read_text())
	building_id = None
	if stem in buildings:
		id_name = str(buildings[stem].get("id_name", ""))
		if id_name.startswith("BUILDINGS."):
			key = id_name.split(".", 1)[1]
			building_id = constants.get("BUILDINGS", {}).get(key)

	out_dir = GODOT_ROOT / "resources" / "gfx" / stem
	out_dir.mkdir(parents=True, exist_ok=True)
	source_mode = "placeholder"
	for anim in ("idle", "working"):
		rel = paths.get(anim, paths.get("idle", ""))
		src = CONTENT_GFX / rel if rel else None
		dst = out_dir / f"{anim}.png"
		if src and src.is_file():
			shutil.copy2(src, dst)
			source_mode = "legacy_png"
		else:
			write_solid_png(dst, 64, 64, (120, 120, 120, 255) if anim == "idle" else (160, 140, 90, 255))

	atlas_db = find_sqlite_with_atlas_table()
	manifest = {
		"building_stem": stem,
		"building_id": building_id,
		"source": source_mode,
		"atlas_sqlite": str(atlas_db) if atlas_db else None,
		"animations": {
			"idle": {"texture": "idle.png", "fps": 1.0},
			"working": {"texture": "working.png", "fps": 4.0},
		},
	}
	(out_dir / "sprite_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
	print(f"Wrote gfx slice for {stem} ({source_mode})")


def export_lumberjack_slice() -> None:
	export_building_slice("lumberjackcamp", LEGACY_BUILDING_GFX["lumberjackcamp"])


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


def write_ground_atlas(out_dir: Path) -> None:
	ground_dir = out_dir / "ground"
	ground_dir.mkdir(parents=True, exist_ok=True)
	path = ground_dir / "atlas.png"
	write_solid_png(path.parent / "_w.png", 32, 16, (31, 71, 140, 255))
	write_solid_png(path.parent / "_c.png", 32, 16, (46, 97, 158, 255))
	write_solid_png(path.parent / "_l.png", 32, 16, (56, 122, 56, 255))
	# Simple horizontal strip (Godot MapView also builds atlas at runtime)
	import shutil

	shutil.copy2(path.parent / "_l.png", path)


def write_gfx_index() -> None:
	index: dict = {
		"buildings": {},
		"ground": {
			"source": "procedural_diamond",
			"tile_w": 32,
			"tile_h": 16,
			"land_rgba": [56, 122, 56, 255],
			"coast_rgba": [46, 97, 158, 255],
			"water_rgba": [31, 71, 140, 255],
			"atlas_texture": "ground/atlas.png",
		},
	}
	gfx_root = GODOT_ROOT / "resources" / "gfx"
	for stem, paths in LEGACY_BUILDING_GFX.items():
		manifest_path = gfx_root / stem / "sprite_manifest.json"
		if manifest_path.is_file():
			index["buildings"][stem] = json.loads(manifest_path.read_text(encoding="utf-8"))
		else:
			index["buildings"][stem] = {"building_stem": stem, "source": "missing"}
	(out := GODOT_ROOT / "resources" / "gfx" / "index.json").write_text(
		json.dumps(index, indent=2, sort_keys=True), encoding="utf-8"
	)
	print(f"Wrote gfx index to {out}")


def main() -> int:
	for stem, paths in LEGACY_BUILDING_GFX.items():
		export_building_slice(stem, paths)
	export_dlc_gfx()
	gfx_root = GODOT_ROOT / "resources" / "gfx"
	write_ground_atlas(gfx_root)
	write_gfx_index()
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
