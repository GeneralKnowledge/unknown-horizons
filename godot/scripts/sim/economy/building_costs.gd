class_name BuildingCosts
extends RefCounted

## Settlement build costs from exported YAML `buildingcosts` (legacy parity).


static func costs_for_building_id(building_id: int) -> Dictionary:
	var export := ContentLoader.load_building_export(
		ContentLoader.stem_for_building_id(building_id)
	)
	var raw: Variant = export.get("buildingcosts", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var out: Dictionary = {}
	for res_key in raw.keys():
		out[int(str(res_key))] = int(raw[res_key])
	return out


static func can_afford(settlement: Settlement, building_id: int) -> bool:
	return missing_resources(settlement, building_id).is_empty()


static func missing_resources(settlement: Settlement, building_id: int) -> Dictionary:
	var missing: Dictionary = {}
	if settlement == null:
		return {GameConstants.RES["GOLD"]: 1}
	var costs := costs_for_building_id(building_id)
	for res_id in costs.keys():
		var need: int = int(costs[res_id])
		var have: int = settlement.inventory.amount(int(res_id))
		if have < need:
			missing[int(res_id)] = need - have
	return missing


static func try_pay(settlement: Settlement, building_id: int) -> bool:
	if settlement == null:
		return false
	var costs := costs_for_building_id(building_id)
	if costs.is_empty():
		return true
	for res_id in costs.keys():
		var need: int = int(costs[res_id])
		if settlement.inventory.amount(int(res_id)) < need:
			return false
	for res_id in costs.keys():
		settlement.inventory.alter(int(res_id), -int(costs[res_id]))
	return true


static func describe_missing(settlement: Settlement, building_id: int) -> String:
	var missing := missing_resources(settlement, building_id)
	if missing.is_empty():
		return ""
	var parts: PackedStringArray = []
	for res_id in missing.keys():
		parts.append("%s (need %d more)" % [_res_label(int(res_id)), int(missing[res_id])])
	return "Not enough resources: %s" % ", ".join(parts)


static func _res_label(res_id: int) -> String:
	for name in GameConstants.RES:
		if int(GameConstants.RES[name]) == res_id:
			return name.to_lower()
	return "res_%d" % res_id
