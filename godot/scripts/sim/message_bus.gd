extends Node

## Sim ↔ view notifications (subset of legacy GUI message flow).

signal building_placed(building: Building)
signal building_removed(building: Building)
signal building_selected(building: Building)
signal settlement_updated
signal inventory_changed(inventory: Inventory)
