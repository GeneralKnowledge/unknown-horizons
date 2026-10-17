class_name DevDebugPanel
extends VBoxContainer

## Development-only shortcuts (resource injection). Not used in release builds.

var session: GameSession
var selected: Building

var _info: Label


func _ready() -> void:
	visible = OS.is_debug_build()
	if not visible:
		return
	_info = Label.new()
	_info.text = "Dev: add 2 trees to selected building"
	add_child(_info)
	var btn := Button.new()
	btn.text = "+2 TREES (selected)"
	btn.pressed.connect(_on_add_trees)
	add_child(btn)


func bind(p_session: GameSession) -> void:
	session = p_session


func set_selected(building: Building) -> void:
	selected = building


func _on_add_trees() -> void:
	if selected == null:
		return
	selected.get_storage().alter(GameConstants.RES["TREES"], 2)
	MessageBus.settlement_updated.emit()
