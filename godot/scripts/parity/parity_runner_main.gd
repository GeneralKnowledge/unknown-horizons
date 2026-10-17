extends Node

## Main scene entry so project autoloads (MessageBus) are available for parity runs.


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	var scenario_path := ""
	var out_path := "user://parity_trace.json"
	var i := 0
	while i < args.size():
		if args[i] == "--out" and i + 1 < args.size():
			out_path = args[i + 1]
			i += 2
			continue
		if args[i] == "--" and i + 1 < args.size():
			scenario_path = args[i + 1]
			i += 2
			continue
		if (
			scenario_path.is_empty()
			and args[i].ends_with(".json")
			and args[i].find("parity") >= 0
		):
			scenario_path = args[i]
		i += 1
	if scenario_path.is_empty():
		push_error(
			"Usage: godot --path godot res://scenes/parity_runner.tscn -- scenario.json [--out trace.json] "
			+ "(args=%s)" % str(args)
		)
		get_tree().quit(1)
		return
	var runner := preload("res://scripts/parity/scenario_runner.gd").new()
	var trace: Dictionary = runner.run_file(scenario_path)
	var write_path := out_path
	if write_path.begins_with("res://") or write_path.begins_with("user://"):
		write_path = ProjectSettings.globalize_path(write_path)
	var file := FileAccess.open(write_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % write_path)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(trace, "\t"))
	file.close()
	print("Wrote %s" % write_path)
	get_tree().quit(0)
