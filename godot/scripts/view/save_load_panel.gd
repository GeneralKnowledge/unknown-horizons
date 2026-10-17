class_name SaveLoadPanel
extends HBoxContainer

signal save_requested
signal load_requested

const DEFAULT_SAVE_PATH := "user://poc_snapshot.json"


func _ready() -> void:
	var save_btn := Button.new()
	save_btn.text = "Save JSON"
	save_btn.pressed.connect(func(): save_requested.emit())
	add_child(save_btn)
	var load_btn := Button.new()
	load_btn.text = "Load JSON"
	load_btn.pressed.connect(func(): load_requested.emit())
	add_child(load_btn)
