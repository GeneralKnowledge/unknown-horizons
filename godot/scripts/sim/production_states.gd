class_name ProductionStates
extends RefCounted

## Mirrors horizons.constants.PRODUCTION.STATES ordering (Enum comparison uses index).

const NONE := 0
const WAITING_FOR_RES := 1
const INVENTORY_FULL := 2
const PRODUCING := 3
const PAUSED := 4
const DONE := 5

static func name_for(state: int) -> String:
	match state:
		NONE: return "none"
		WAITING_FOR_RES: return "waiting_for_res"
		INVENTORY_FULL: return "inventory_full"
		PRODUCING: return "producing"
		PAUSED: return "paused"
		DONE: return "done"
		_: return "unknown"
