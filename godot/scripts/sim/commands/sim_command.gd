class_name SimCommand
extends RefCounted

## Base for session mutations (mirrors horizons/command/Command).


func execute(_session: GameSession) -> Variant:
	push_error("SimCommand.execute not implemented")
	return null
