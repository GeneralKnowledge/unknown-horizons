class_name ProviderHandler
extends RefCounted

## Legacy horizons.world.providerhandler.ProviderHandler — index buildings by provided resource.


var _providers: Array = []
var _by_resource: Dictionary = {} # int res_id -> Array[Building]


func register(building: Building, resource_ids: Array) -> void:
	if building in _providers:
		return
	_providers.append(building)
	for res_key in resource_ids:
		var res_id := int(res_key)
		if not _by_resource.has(res_id):
			_by_resource[res_id] = []
		var list: Array = _by_resource[res_id]
		if building not in list:
			list.append(building)


func unregister(building: Building) -> void:
	if building not in _providers:
		return
	_providers.erase(building)
	for res_id in _by_resource.keys():
		var list: Array = _by_resource[res_id]
		if building in list:
			list.erase(building)


func buildings_for_resources(reslist: Array) -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for res_key in reslist:
		var res_id := int(res_key)
		if not _by_resource.has(res_id):
			continue
		for building in _by_resource[res_id]:
			if building not in seen:
				seen[building] = true
				out.append(building)
	return out
