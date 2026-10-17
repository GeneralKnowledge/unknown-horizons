extends GutTest


func test_build_context_activates_build_tool() -> void:
	var session := GameSession.new()
	session.load_test_map()
	var tool := BuildTool.new(session)
	var map_view := MapView.new()
	var mgr := ViewContextManager.new()
	add_child_autofree(mgr)
	mgr.setup(session, tool, map_view)
	mgr.set_context(&"select")
	assert_false(tool.active)
	mgr.set_context(&"build")
	assert_true(tool.active)
	mgr.set_context(&"tear")
	assert_true(tool.tear_mode)
