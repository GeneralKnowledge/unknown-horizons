extends GutTest


func test_migrate_v3_is_noop() -> void:
	var snap := {
		"schema_version": 3,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [],
	}
	var out := SaveMigration.migrate(snap, 3)
	assert_eq(3, out["schema_version"])
