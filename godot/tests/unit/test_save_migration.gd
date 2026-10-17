extends GutTest


func test_migrate_v3_is_noop() -> void:
	var snap := {
		"schema_version": 3,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [],
	}
	var prep := SaveMigration.try_prepare(snap)
	assert_true(prep["ok"])
	assert_eq(3, prep["data"]["schema_version"])
