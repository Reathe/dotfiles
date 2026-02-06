local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.default_prog = { "nu" }
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.use_fancy_tab_bar = false
config.use_dead_keys = false

local act = wezterm.action
config.keys = {
	{
		key = "h",
		mods = "ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "ALT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "ALT",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "H",
		mods = "ALT|SHIFT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "J",
		mods = "ALT|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{ key = "K", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{
		key = "L",
		mods = "ALT|SHIFT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = act.SplitPane({ direction = "Left" }),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = act.SplitPane({ direction = "Down" }),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = act.SplitPane({ direction = "Up" }),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = act.SplitPane({ direction = "Right" }),
	},
	{
		key = "w",
		mods = "CTRL",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "Enter",
		mods = "CTRL",
		action = act.ToggleFullScreen,
	},
	{
		key = "Enter",
		mods = "ALT|SHIFT",
		action = act.TogglePaneZoomState,
	},
}

config.window_background_gradient = {
	interpolation = "Linear",

	orientation = "Vertical",

	blend = "Rgb",

	colors = {
		"#11111b",
		"#181825",
	},
}

return config
