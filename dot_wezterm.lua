local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.default_prog = { "nu" }
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.7
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.use_fancy_tab_bar = false
config.use_dead_keys = false

local act = wezterm.action
config.keys = {
	{
		key = "H",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "L",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "K",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "J",
		mods = "CTRL|SHIFT",
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
		key = "_",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},

	{
		key = "+",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CTRL",
		action = act.CloseCurrentPane({ confirm = true }),
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
