class_name DemoSuccessPanel
extends PanelContainer

signal continue_playing
signal restart_demo
signal return_to_menu

var _continue_btn: Button
var _restart_btn: Button
var _menu_btn: Button


func _ready() -> void:
	var pack_theme := ContentTheme.get_ui_theme()
	if pack_theme != null:
		theme = pack_theme
	custom_minimum_size = Vector2(360, 200)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "Settlement milestone complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var body := Label.new()
	body.name = "SuccessBody"
	body.text = PlayableDemoConfig.success_message()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(body)
	_continue_btn = _btn("Continue playing", func(): continue_playing.emit())
	v.add_child(_continue_btn)
	_restart_btn = _btn("Restart demo", func(): restart_demo.emit())
	v.add_child(_restart_btn)
	_menu_btn = _btn("Return to menu", func(): return_to_menu.emit())
	v.add_child(_menu_btn)
	visible = false


func show_success() -> void:
	var body := get_node_or_null("VBox/SuccessBody") as Label
	if body != null:
		body.text = PlayableDemoConfig.success_message()
	visible = true


func hide_success() -> void:
	visible = false


func _btn(label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(cb)
	return b
