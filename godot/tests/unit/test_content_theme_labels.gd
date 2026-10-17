extends GutTest


func test_parse_ui_labels_v2_schema() -> void:
	var data := {
		"schema_version": 1,
		"labels": {"lumberjackcamp": "Timber Camp", "tree": "Pine"},
	}
	var labels := ContentTheme.parse_ui_labels_file(data)
	assert_eq("Timber Camp", labels.get("lumberjackcamp"))
	assert_eq("Pine", labels.get("tree"))


func test_parse_ui_labels_legacy_flat_map() -> void:
	var data := {"brickyard": "Kiln", "farm": "Plot"}
	var labels := ContentTheme.parse_ui_labels_file(data)
	assert_eq("Kiln", labels.get("brickyard"))


func test_northern_pack_labels_load() -> void:
	var labels := ContentTheme.load_ui_labels_for_pack("northern_company")
	assert_eq("Kiln Works", labels.get("brickyard"))
