class_name LegacySettlerComponent
extends RefCounted

## Residential settler state restored from legacy SQLite (tier limits, happiness storage, monthly tax).

const TIER_INHABITANTS_MAX := [3, 6, 10, 15, 21, 28]
const TIER_TAX_INCOME := [2, 3, 5, 8, 13, 21]
const HAPPINESS_INCREASE_AT := 70
const HAPPINESS_DECREASE_BELOW := 30
const HAPPINESS_RES_LIMIT := 100

var building: Building
var session: GameSession
var level: int = 0
var inhabitants: int = 0
var last_tax_payed: int = 0


func _init(
	p_building: Building,
	p_session: GameSession,
	p_inhabitants: int,
	p_last_tax: int,
	p_level: int = 0,
	p_remaining_ticks_of_month: int = -1
) -> void:
	building = p_building
	session = p_session
	level = maxi(0, p_level)
	inhabitants = maxi(0, p_inhabitants)
	last_tax_payed = maxi(0, p_last_tax)
	inhabitants = mini(inhabitants, inhabitants_max())
	_ensure_happiness_slot()
	var interval := session.scheduler.get_ticks_of_month()
	var run_in := p_remaining_ticks_of_month if p_remaining_ticks_of_month >= 0 else interval
	session.scheduler.add_new_object(_on_monthly_tick, self, run_in, -1, interval)


func inhabitants_max() -> int:
	if level < 0 or level >= TIER_INHABITANTS_MAX.size():
		return TIER_INHABITANTS_MAX[0]
	return TIER_INHABITANTS_MAX[level]


func inhabitants_min() -> int:
	if level <= 0:
		return 0
	return TIER_INHABITANTS_MAX[level - 1]


func tax_base() -> int:
	if level < 0 or level >= TIER_TAX_INCOME.size():
		return TIER_TAX_INCOME[0]
	return TIER_TAX_INCOME[level]


func get_happiness() -> int:
	var inv := building.get_storage()
	if inv == null:
		return 0
	var hid := int(GameConstants.RES["HAPPINESS"])
	var stored := inv.amount(hid)
	return clampi(int(round(stored)), 0, HAPPINESS_RES_LIMIT)


func _ensure_happiness_slot() -> void:
	var inv := building.get_storage()
	if inv == null:
		return
	var hid := int(GameConstants.RES["HAPPINESS"])
	if not inv.has_resource_slot(hid):
		inv.add_resource_slot(hid, HAPPINESS_RES_LIMIT)


func _on_monthly_tick() -> void:
	if inhabitants <= 0:
		return
	_pay_tax()
	_inhabitant_check()


func _settlement_tax_setting() -> float:
	var settlement := building.settlement
	if settlement == null:
		return 1.0
	return settlement.legacy_tax_setting_for_level(level)


func _pay_tax() -> void:
	var happiness := get_happiness()
	var happiness_tax_modifier := 0.5 + (float(happiness) / 70.0)
	var inh_max := maxi(1, inhabitants_max())
	var inhabitants_tax_modifier := float(inhabitants) / float(inh_max)
	var taxes := (
		float(tax_base())
		* _settlement_tax_setting()
		* happiness_tax_modifier
		* inhabitants_tax_modifier
	)
	var real_taxes := int(round(taxes))
	var gold_id := int(GameConstants.RES["GOLD"])
	var inv := building.settlement.inventory
	if not inv.has_resource_slot(gold_id):
		inv.add_resource_slot(gold_id, 999999)
	inv.alter(gold_id, real_taxes)
	last_tax_payed = real_taxes
	var difference := 1.0 - _settlement_tax_setting()
	var happiness_decrease := int(round(10.0 * difference - 6.0 * abs(difference))) - 6
	var hid := int(GameConstants.RES["HAPPINESS"])
	var storage := building.get_storage()
	if storage != null:
		storage.alter(hid, happiness_decrease)


func _inhabitant_check() -> void:
	var happiness := get_happiness()
	var change := 0
	if happiness > HAPPINESS_INCREASE_AT and inhabitants < inhabitants_max():
		change = 1
	elif happiness < HAPPINESS_DECREASE_BELOW and inhabitants > 1:
		change = -1
	if change != 0:
		inhabitants += change


static func total_inhabitants(session: GameSession) -> int:
	var total := 0
	for b in session.get_buildings_on_island(session.island):
		if b.settler != null:
			total += b.settler.inhabitants
	return total
