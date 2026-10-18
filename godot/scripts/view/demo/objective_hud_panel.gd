class_name ObjectiveHudPanel
extends PanelContainer

signal pause_toggled

var tracker: DemoObjectiveTracker

@onready var _title: Label
@onready var _progress: Label
@onready var _hint: Label
@onready var _pause_btn: Button


func _ready() -> void:
	var pack_theme := ContentTheme.get_ui_theme()
	if pack_theme != null:
		theme = pack_theme
	custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	add_child(v)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_title)
	_progress = Label.new()
	_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_progress)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_hint)
	_pause_btn = Button.new()
	_pause_btn.text = "Pause simulation"
	_pause_btn.pressed.connect(_on_pause_pressed)
	v.add_child(_pause_btn)
	var save_note := Label.new()
	save_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if OS.has_feature("web"):
		save_note.text = "Progress: Save JSON then Download save before closing the tab."
	else:
		save_note.text = "Progress: Save JSON in the HUD (enables Continue on the title menu)."
	v.add_child(save_note)
	if tracker != null:
		_connect_tracker(tracker)
	_refresh()


func bind_tracker(p_tracker: DemoObjectiveTracker) -> void:
	if tracker != null and tracker.state_changed.is_connected(_refresh):
		tracker.state_changed.disconnect(_refresh)
	tracker = p_tracker
	if is_node_ready():
		_connect_tracker(p_tracker)
	_refresh()


func _connect_tracker(p_tracker: DemoObjectiveTracker) -> void:
	if not p_tracker.state_changed.is_connected(_refresh):
		p_tracker.state_changed.connect(_refresh)


func set_paused(paused: bool) -> void:
	if _pause_btn != null:
		_pause_btn.text = "Resume simulation" if paused else "Pause simulation"


func _on_pause_pressed() -> void:
	pause_toggled.emit()


func _refresh() -> void:
	if tracker == null:
		if _title != null:
			_title.text = "Objective"
		return
	if _title != null:
		_title.text = tracker.objective_title()
	if _progress != null:
		_progress.text = tracker.progress_line()
	if _hint != null:
		_hint.text = tracker.hint_text()
