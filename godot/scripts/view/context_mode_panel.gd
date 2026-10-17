class_name ContextModePanel
extends HBoxContainer

signal context_selected(context_name: StringName)

var _build_btn: Button
var _select_btn: Button
var _tear_btn: Button


func _ready() -> void:
	var label := Label.new()
	label.text = "Mode:"
	add_child(label)
	_build_btn = Button.new()
	_build_btn.text = "Build"
	_build_btn.pressed.connect(func(): context_selected.emit(&"build"))
	add_child(_build_btn)
	_select_btn = Button.new()
	_select_btn.text = "Select"
	_select_btn.pressed.connect(func(): context_selected.emit(&"select"))
	add_child(_select_btn)
	_tear_btn = Button.new()
	_tear_btn.text = "Tear"
	_tear_btn.pressed.connect(func(): context_selected.emit(&"tear"))
	add_child(_tear_btn)


func highlight(context_name: StringName) -> void:
	_build_btn.disabled = context_name == &"build"
	_select_btn.disabled = context_name == &"select"
	_tear_btn.disabled = context_name == &"tear"
