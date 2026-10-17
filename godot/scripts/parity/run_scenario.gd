extends SceneTree

const _ScenarioRunner = preload("res://scripts/parity/scenario_runner.gd")

## Headless CLI: godot --headless --path godot -s res://scripts/parity/run_scenario.gd -- scenario.json [--out path]


func _init() -> void:
	var args := OS.get_cmdline_args()
	var scenario_path := ""
	var out_path := "/tmp/uh-parity/trace_godot.json"
	for i in range(args.size()):
		if args[i] == "--" and i + 1 < args.size():
			scenario_path = args[i + 1]
		if args[i] == "--out" and i + 1 < args.size():
			out_path = args[i + 1]
	if scenario_path.is_empty():
		push_error("Usage: -s res://scripts/parity/run_scenario.gd -- path/to/scenario.json [--out trace.json]")
		quit(1)
		return
	var runner := _ScenarioRunner.new()
	var trace: Dictionary = runner.run_file(scenario_path)
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % out_path)
		quit(1)
		return
	file.store_string(JSON.stringify(trace, "\t"))
	file.close()
	print("Wrote %s" % out_path)
	quit(0)
