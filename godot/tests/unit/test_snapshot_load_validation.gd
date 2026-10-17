extends GutTest


func _settled_session() -> GameSession:
	var settled := GameSession.settle()
	return settled.session as GameSession


func test_valid_v3_round_trip() -> void:
	var session := _settled_session()
	var snap := session.to_snapshot()
	var session2 := GameSession.new()
	session2.load_test_map()
	var result := session2.try_load_snapshot(snap)
	assert_true(result["ok"], str(result.get("error", "")))
	assert_eq(1, session2.get_buildings_on_island(session2.island).size())


func test_migrate_v0_v1_v2() -> void:
	for version in [0, 1, 2]:
		var snap := {
			"schema_version": version,
			"next_worldid": 5,
			"settlement_inventory": {},
			"buildings": [],
		}
		var prep := SaveMigration.try_prepare(snap)
		assert_true(prep["ok"], "v%d: %s" % [version, prep.get("error", "")])
		assert_eq(3, int(prep["data"]["schema_version"]))


func test_missing_schema_version_rejected() -> void:
	var session := _settled_session()
	var before := session.get_buildings_on_island(session.island).size()
	var result := session.try_load_snapshot({"next_worldid": 2, "buildings": []})
	assert_false(result["ok"])
	assert_eq("missing_schema_version", result["error"])
	assert_eq(before, session.get_buildings_on_island(session.island).size())


func test_future_schema_rejected() -> void:
	var session := _settled_session()
	var before := session.get_buildings_on_island(session.island).size()
	var snap := {
		"schema_version": GameSession.SNAPSHOT_VERSION + 1,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [],
	}
	var result := session.try_load_snapshot(snap)
	assert_false(result["ok"])
	assert_eq("unsupported_future_schema_version", result["error"])
	assert_eq(before, session.get_buildings_on_island(session.island).size())


func test_malformed_building_record_rejected() -> void:
	var session := _settled_session()
	var before := session.get_buildings_on_island(session.island).size()
	var snap := {
		"schema_version": 3,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [{"worldid": 1, "building_id": "not_int", "x": 0, "y": 0}],
	}
	var result := session.try_load_snapshot(snap)
	assert_false(result["ok"])
	assert_true(str(result["error"]).begins_with("invalid_building_field_type"))
	assert_eq(before, session.get_buildings_on_island(session.island).size())


func test_missing_required_building_field() -> void:
	var session := _settled_session()
	var snap := {
		"schema_version": 3,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [{"worldid": 1, "building_id": GameConstants.BUILDINGS["LUMBERJACK"]}],
	}
	var result := session.try_load_snapshot(snap)
	assert_false(result["ok"])
	assert_true(str(result["error"]).begins_with("missing_building_field"))


func test_unknown_building_id_rejected() -> void:
	var session := _settled_session()
	var snap := {
		"schema_version": 3,
		"next_worldid": 2,
		"settlement_inventory": {},
		"buildings": [
			{
				"worldid": 1,
				"building_id": 99999999,
				"x": 30,
				"y": 30,
			},
		],
	}
	var result := session.try_load_snapshot(snap)
	assert_false(result["ok"])
	assert_true(str(result["error"]).begins_with("unknown_building_id"))
