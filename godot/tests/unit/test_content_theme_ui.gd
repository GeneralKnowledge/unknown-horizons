extends GutTest


func test_northern_company_theme_resource_loads() -> void:
	const PATH := "res://resources/dlc/northern_company/themes/northern_company_default.tres"
	assert_true(ResourceLoader.exists(PATH))
	var theme: Variant = load(PATH)
	assert_true(theme is Theme)


func test_get_ui_theme_when_pack_active() -> void:
	var prev_pack := ContentTheme.pack_id
	var prev_theme_id := ContentTheme.ui_theme_id
	ContentTheme.pack_id = "northern_company"
	ContentTheme.ui_theme_id = "northern_company_default"
	ContentTheme._ui_theme = null
	var theme := ContentTheme.get_ui_theme()
	assert_true(theme is Theme)
	ContentTheme.pack_id = prev_pack
	ContentTheme.ui_theme_id = prev_theme_id
	ContentTheme._ui_theme = null
