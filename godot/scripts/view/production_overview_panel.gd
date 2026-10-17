class_name ProductionOverviewPanel
extends VBoxContainer

var _title: Label
var _state: Label
var _toggle_btn: Button
var session: GameSession
var selected: Building


func _ready() -> void:
	_title = Label.new()
	_title.text = "Production"
	add_child(_title)
	_state = Label.new()
	_state.text = "—"
	add_child(_state)
	_toggle_btn = Button.new()
	_toggle_btn.text = "Toggle producer active"
	_toggle_btn.pressed.connect(_on_toggle)
	add_child(_toggle_btn)


func bind(p_session: GameSession) -> void:
	session = p_session


func set_selected(building: Building) -> void:
	selected = building
	_refresh()


func _refresh() -> void:
	if selected == null:
		_state.text = "Select a building with a producer"
		_toggle_btn.disabled = true
		return
	var producer := selected.get_producer()
	if producer == null:
		_state.text = "No producer on this building"
		_toggle_btn.disabled = true
		return
	_state.text = "State: %s | active: %s" % [
		ProductionStates.name_for(producer._get_current_state()),
		str(producer.is_active()),
	]
	_toggle_btn.disabled = false


func _on_toggle() -> void:
	if session == null or selected == null:
		return
	session.manager.execute(ToggleActiveCommand.new(selected))
	_refresh()
	MessageBus.settlement_updated.emit()
