class_name LegacySettlerComponent
extends RefCounted

## Minimal settler/residential state restored from legacy SQLite (not full happiness sim).

const TICKS_PER_TAX_CYCLE := 1008

var building: Building
var session: GameSession
var inhabitants: int = 0
var last_tax_payed: int = 0


func _init(p_building: Building, p_session: GameSession, p_inhabitants: int, p_last_tax: int) -> void:
	building = p_building
	session = p_session
	inhabitants = maxi(0, p_inhabitants)
	last_tax_payed = maxi(0, p_last_tax)
	if inhabitants > 0:
		session.scheduler.add_new_object(_on_tax_tick, self, TICKS_PER_TAX_CYCLE, -1, TICKS_PER_TAX_CYCLE)


func _on_tax_tick() -> void:
	if inhabitants <= 0:
		return
	# Legacy settlers credit settlement treasury; PoC uses flat gold per inhabitant per cycle.
	var gold_id := int(GameConstants.RES["GOLD"])
	var inv := building.settlement.inventory
	if not inv.has_resource_slot(gold_id):
		inv.add_resource_slot(gold_id, 999999)
	inv.alter(gold_id, inhabitants)
	last_tax_payed = session.scheduler.cur_tick


static func total_inhabitants(session: GameSession) -> int:
	var total := 0
	for b in session.get_buildings_on_island(session.island):
		if b.settler != null:
			total += b.settler.inhabitants
	return total
