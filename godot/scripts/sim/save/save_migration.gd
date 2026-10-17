class_name SaveMigration
extends RefCounted

## Versioned snapshot migrations before GameSession.load_snapshot applies data.

const CURRENT_VERSION := GameSession.SNAPSHOT_VERSION


static func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var version := from_version
	var working: Dictionary = data.duplicate(true)
	while version < CURRENT_VERSION:
		match version:
			0, 1, 2:
				working["schema_version"] = 3
				version = 3
			3:
				break
			_:
				push_error("Unsupported save schema_version: %d" % version)
				return data
	working["schema_version"] = CURRENT_VERSION
	return working
