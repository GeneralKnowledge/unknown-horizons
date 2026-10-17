extends GutTest


func test_northern_manifest_lists_gfx_overrides() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://resources/dlc/northern_company/manifest.json")
	)
	var overrides: Array = manifest.get("gfx_stem_overrides", [])
	assert_true("lumberjackcamp" in overrides)
	assert_true(manifest.has("gfx_stem_aliases"))


func test_pack_gfx_has_lumberjack_override_tree() -> void:
	var path := "res://resources/dlc/northern_company/gfx/lumberjackcamp/sprite_manifest.json"
	assert_true(
		FileAccess.file_exists(path),
		"Run export_gfx.py to populate pack stem overrides"
	)
