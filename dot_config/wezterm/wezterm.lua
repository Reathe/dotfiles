local wezterm = require("wezterm") ---@type Wezterm
local config = {} ---@type Config

if wezterm.config_builder then
	config = wezterm.config_builder()
end

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.ssh_backend = "Ssh2"
end
config.prefer_egl = true
config.default_prog = { "nu" }
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "NONE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.use_dead_keys = false
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm") ---@type SWS
local domains = require("domains_sws")
domains.patch_workspace_switcher(workspace_switcher)

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez") ---@type TablineWez

local act = wezterm.action
config.keys = {
	-- workspace_switcher
	{ key = "S", mods = "LEADER|CTRL", action = workspace_switcher.switch_workspace() },
	{ key = "s", mods = "LEADER|CTRL", action = workspace_switcher.switch_to_prev_workspace() },
	-- wezterm keybinds
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "H", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "J", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "K", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "L", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "h", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Left" }) },
	{ key = "j", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Down" }) },
	{ key = "k", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Up" }) },
	{ key = "l", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Right" }) },
	{ key = "w", mods = "CTRL", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "Enter", mods = "CTRL", action = act.ToggleFullScreen },
	{ key = "Enter", mods = "ALT|SHIFT", action = act.TogglePaneZoomState },
	-- Smart Copy: If text is selected, copy it. If not, send SIGINT (Ctrl+C)
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local selection = window:get_selection_text_for_pane(pane)
			if selection == "" then
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			else
				window:perform_action(act.CopyTo("Clipboard"), pane)
				window:perform_action(act.ClearSelection, pane)
			end
		end),
	},
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

tabline.setup({
	options = {},
	sections = {
		tabline_x = {
			-- disabled because cpu / ram takes a long time to execute which makes the workspace name update late
			-- { "cpu", use_pwsh = true, throttle = 15 },
			-- { "ram", use_pwsh = true, throttle = 15 },
		},
	},
	extensions = { "smart_workspace_switcher" },
})
tabline.apply_to_config(config)

return config
