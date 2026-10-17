class_name SnapshotValidator
extends RefCounted

## Validates JSON snapshot shape before GameSession mutates state.


static func validate(data: Dictionary) -> Dictionary:
	if not data.has("schema_version"):
		return _err("missing_schema_version")
	var version := int(data["schema_version"])
	if version < 0:
		return _err("invalid_schema_version")
	if version > GameSession.SNAPSHOT_VERSION:
		return _err("unsupported_future_schema_version")

	if not data.has("next_worldid"):
		return _err("missing_next_worldid")
	if typeof(data["next_worldid"]) != TYPE_INT and typeof(data["next_worldid"]) != TYPE_FLOAT:
		return _err("invalid_next_worldid_type")
	if int(data["next_worldid"]) < 1:
		return _err("invalid_next_worldid_value")

	if data.has("settlement_inventory"):
		var inv_err := _validate_inventory(data["settlement_inventory"], "settlement_inventory")
		if not inv_err.is_empty():
			return _err(inv_err)

	if not data.has("buildings"):
		return _err("missing_buildings")
	if typeof(data["buildings"]) != TYPE_ARRAY:
		return _err("invalid_buildings_type")

	for i in data["buildings"].size():
		var row: Variant = data["buildings"][i]
		var row_err := _validate_building_row(row, i)
		if not row_err.is_empty():
			return _err(row_err)

	return {"ok": true, "error": ""}


static func _validate_building_row(row: Variant, index: int) -> String:
	if typeof(row) != TYPE_DICTIONARY:
		return "invalid_building_record_type:%d" % index
	for key in ["worldid", "building_id", "x", "y"]:
		if not row.has(key):
			return "missing_building_field:%s:%d" % [key, index]
		if typeof(row[key]) != TYPE_INT and typeof(row[key]) != TYPE_FLOAT:
			return "invalid_building_field_type:%s:%d" % [key, index]
	var bid := int(row["building_id"])
	if bid <= 0:
		return "invalid_building_id:%d" % index
	if not ContentLoader.is_known_building_id(bid):
		return "unknown_building_id:%d" % index
	if row.has("storage"):
		var storage_err := _validate_inventory(row["storage"], "buildings[%d].storage" % index)
		if not storage_err.is_empty():
			return storage_err
	if row.has("producer_active") and typeof(row["producer_active"]) != TYPE_BOOL:
		return "invalid_producer_active_type:%d" % index
	return ""


static func _validate_inventory(inv: Variant, label: String) -> String:
	if typeof(inv) != TYPE_DICTIONARY:
		return "invalid_inventory_type:%s" % label
	for key in inv.keys():
		if typeof(inv[key]) != TYPE_INT and typeof(inv[key]) != TYPE_FLOAT:
			return "invalid_inventory_amount:%s" % label
	return ""


static func _err(code: String) -> Dictionary:
	return {"ok": false, "error": code}
