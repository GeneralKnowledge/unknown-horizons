class_name HealthComponent
extends RefCounted

var maxhealth: int = 1000
var health: int = 1000
var home_building: Building


func _init(p_building: Building, config: Dictionary) -> void:
	home_building = p_building
	maxhealth = int(config.get("maxhealth", 1000))
	health = maxhealth


func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)


func is_destroyed() -> bool:
	return health <= 0
