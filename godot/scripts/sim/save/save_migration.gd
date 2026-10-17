class_name SaveMigration
extends RefCounted

## Versioned snapshot migrations before GameSession.load_snapshot applies data.
## Does not implement legacy SQLite SavegameUpgrader — JSON schema only.

const CURRENT_VERSION := GameSession.SNAPSHOT_VERSION


static func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var result := try_prepare(data)
	if not result["ok"]:
		push_error("SaveMigration: %s" % str(result.get("error", "")))
		return data
	return result["data"]


static func try_prepare(data: Dictionary) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return _fail("invalid_snapshot_root")
	if not data.has("schema_version"):
		return _fail("missing_schema_version")

	var version := int(data["schema_version"])
	if version < 0:
		return _fail("invalid_schema_version")
	if version > CURRENT_VERSION:
		return _fail("unsupported_future_schema_version")

	var working: Dictionary = data.duplicate(true)
	while version < CURRENT_VERSION:
		match version:
			0, 1, 2:
				working["schema_version"] = 3
				version = 3
			3:
				break
			_:
				return _fail("unsupported_schema_version:%d" % version)
	working["schema_version"] = CURRENT_VERSION
	return {"ok": true, "error": "", "data": working}


static func _fail(code: String) -> Dictionary:
	return {"ok": false, "error": code, "data": {}}
