class_name ProductionUtilization
extends RefCounted

## Legacy horizons.world.production.utilization (FieldUtilization / FullUtilization).


static func create(kind: String) -> ProductionUtilization:
	match kind:
		"FieldUtilization":
			return FieldUtilization.new()
		"FullUtilization":
			return FullUtilization.new()
		_:
			return FullUtilization.new()


func capacity_utilization(_producer: Producer) -> float:
	return 1.0


func capacity_utilization_below(limit: float, producer: Producer, scheduler: GameScheduler) -> bool:
	var capac := capacity_utilization(producer)
	return capac < limit


class FieldUtilization extends ProductionUtilization:
	const MAX_FIELDS_POSSIBLE := 8

	func capacity_utilization(producer: Producer) -> float:
		var building: Building = producer.instance as Building
		if building == null:
			return 0.0
		var providers: Array = building.get_providers()
		var result := float(providers.size()) / float(MAX_FIELDS_POSSIBLE)
		return clampf(result, 0.0, 1.0)


class FullUtilization extends ProductionUtilization:
	func capacity_utilization(_producer: Producer) -> float:
		return 1.0
