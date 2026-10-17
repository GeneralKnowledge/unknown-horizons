class_name HealthComponent
extends RefCounted

signal destroyed

var maxhealth: int = 1000
var health: int = 1000
var home_building: Building


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	maxhealth = int(config.get("maxhealth", 1000))
	health = maxhealth


func deal_damage(_weapon_id: int, damage: int) -> void:
	health = maxi(0, health - int(damage))
	if health <= 0:
		destroyed.emit()
		if home_building != null and home_building.settlement != null:
			home_building.settlement.remove_building(home_building)


func take_damage(amount: int) -> void:
	deal_damage(0, amount)


func is_destroyed() -> bool:
	return health <= 0
