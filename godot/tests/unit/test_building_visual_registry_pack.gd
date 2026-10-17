extends GutTest


func test_manifest_paths_prefers_pack_gfx_root() -> void:
	var prev_pack := ContentTheme.pack_id
	var prev_root := ContentTheme.gfx_root
	ContentTheme.pack_id = "northern_company"
	ContentTheme.gfx_root = "res://resources/dlc/northern_company/gfx"
	var paths := BuildingVisualRegistry.manifest_paths_for_stem("lumberjackcamp")
	assert_gt(paths.size(), 1)
	assert_true(str(paths[0]).contains("northern_company/gfx"))
	ContentTheme.pack_id = prev_pack
	ContentTheme.gfx_root = prev_root


func test_pack_tint_from_sprite_manifest() -> void:
	var prev_root := ContentTheme.gfx_root
	ContentTheme.gfx_root = "res://resources/dlc/northern_company/gfx"
	var c := BuildingVisualRegistry.get_dlc_tint("northern_warehouse")
	assert_ne(Color.WHITE, c)
	ContentTheme.gfx_root = prev_root
