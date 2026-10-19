extends GutTest

const SHOWCASE := "res://resources/demo/northern_village_showcase.json"
const EXPEDITION := "res://resources/demo/playable_northern_expedition.json"


func test_showcase_schema_validates() -> void:
	var doc := DemoScenarioDocument.load_file(SHOWCASE)
	assert_true(doc.validate().is_empty())
	assert_eq(1, doc.schema_version())
	assert_eq("showcase", doc.kind())
	assert_eq("northern_village_showcase", doc.id())


func test_expedition_schema_validates() -> void:
	var doc := DemoScenarioDocument.load_file(EXPEDITION)
	assert_true(doc.validate().is_empty())
	assert_eq("playable", doc.kind())
	assert_eq(8, doc.steps().size())


func test_invalid_schema_version_warns_but_boots() -> void:
	var data := DemoScenarioDocument.load_file(SHOWCASE).raw.duplicate(true)
	data["schema_version"] = 99
	var doc := DemoScenarioDocument.from_dict(data)
	assert_false(doc.validate().is_empty())
	var session := doc.boot_session(0.0)
	assert_not_null(session)
