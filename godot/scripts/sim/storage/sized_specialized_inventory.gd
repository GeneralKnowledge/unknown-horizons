class_name SizedSpecializedInventory
extends SpecializedInventory

var _slot_limits: Dictionary = {}


func _init(slot_sizes: Dictionary = {}) -> void:
	for res in slot_sizes.keys():
		add_resource_slot(int(res), int(slot_sizes[res]))


func alter(res: int, amount: int) -> int:
	if not has_resource_slot(res):
		return amount
	if amount > 0:
		var storeable := get_free_space_for(res)
		if amount > storeable:
			var ret := super.alter(res, storeable)
			return (amount - storeable) + ret
	return super.alter(res, amount)


func get_limit(res: int = -1) -> int:
	if res < 0:
		return 0
	return int(_slot_limits.get(res, 0))


func add_resource_slot(res: int, size: int = 0) -> void:
	super.add_resource_slot(res)
	assert(size >= 0)
	_slot_limits[res] = size
