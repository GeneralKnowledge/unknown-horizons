"""Install minimal fife stubs so SP game tests can import without the real engine."""

from __future__ import annotations

import sys
from types import ModuleType
from unittest.mock import MagicMock


def install_fife_stubs() -> None:
	if "fife" in sys.modules and getattr(sys.modules["fife"], "_uh_parity_stub", False):
		return

	fife_pkg = ModuleType("fife")
	fife_pkg._uh_parity_stub = True  # type: ignore[attr-defined]
	fife_mod = MagicMock(name="fife_module")

	class _FifeListenerMeta(type):
		pass

	class _FifeListener(metaclass=_FifeListenerMeta):
		pass

	for listener in (
		"IKeyListener",
		"IMouseListener",
		"IGui",
		"IWidget",
		"IClickListener",
		"IScrollListener",
	):
		setattr(fife_mod, listener, _FifeListener)

	fife_pkg.fife = fife_mod

	extensions = ModuleType("fife.extensions")
	pychan = ModuleType("fife.extensions.pychan")
	widgets = ModuleType("fife.extensions.pychan.widgets")
	events = ModuleType("fife.extensions.pychan.events")
	tools = ModuleType("fife.extensions.pychan.tools")
	for name in (
		"Container",
		"Icon",
		"Label",
		"Button",
		"ScrollArea",
		"ListBox",
		"TextBox",
		"HBox",
		"VBox",
	):
		setattr(widgets, name, MagicMock())
	events.EventMapper = MagicMock
	pychan.widgets = widgets
	pychan.events = events
	pychan.tools = tools
	extensions.pychan = pychan
	fife_pkg.extensions = extensions

	sys.modules["fife"] = fife_pkg
	sys.modules["fife.fife"] = fife_mod
	sys.modules["fife.extensions"] = extensions
	sys.modules["fife.extensions.pychan"] = pychan
	sys.modules["fife.extensions.pychan.widgets"] = widgets
	sys.modules["fife.extensions.pychan.events"] = events
	sys.modules["fife.extensions.pychan.tools"] = tools

	# Scheduler imports horizons.main only for side effects; stub GUI stack.
	gui_mod = ModuleType("horizons.gui")
	gui_mod.Gui = MagicMock
	sys.modules["horizons.gui"] = gui_mod
	main_mod = ModuleType("horizons.main")
	main_mod.set_debug_log = lambda *args, **kwargs: None  # type: ignore[attr-defined]
	sys.modules["horizons.main"] = main_mod
