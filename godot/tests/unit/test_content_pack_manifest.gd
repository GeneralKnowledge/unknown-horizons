extends GutTest


func test_northern_manifest_fields_for_view_layer() -> void:
	const PATH := "res://resources/dlc/northern_company/manifest.json"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(manifest.has("gfx_root"))
	assert_true(manifest.has("sounds_manifest"))
	assert_true(manifest.has("ui_theme"))
	var sounds_path := "res://resources/dlc/northern_company/%s" % str(manifest.get("sounds_manifest"))
	assert_true(FileAccess.file_exists(sounds_path))
