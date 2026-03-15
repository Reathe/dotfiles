local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local M = {}

---Patch the workspace switcher to add SSH domain support.
---SSH entries create a new workspace connected to the domain instead of a local path.
function M.patch_workspace_switcher(workspace_switcher)
	workspace_switcher.switch_workspace = function(opts)
		return wezterm.action_callback(function(window, pane)
			local choices = workspace_switcher.get_choices(opts)

			for _, domain in ipairs(wezterm.default_ssh_domains()) do
				table.insert(choices, {
					id = "domain:ssh:" .. domain.name,
					label = wezterm.format({
						{ Foreground = { Color = "cyan" } },
						{ Text = "󰌘 SSH  " .. domain.name },
					}),
				})
			end

			window:perform_action(
				act.InputSelector({
					title = "Choose Workspace",
					description = "Select a workspace and press Enter = accept, Esc = cancel, / = filter",
					fuzzy_description = "Workspace to switch: ",
					choices = choices,
					fuzzy = true,
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if not id or not label then
							return
						end

						-- SSH domain: create workspace connected to remote domain
						if id:find("^domain:ssh:") then
							---@type string
							local domain_name = id:gsub("^domain:ssh:", "")
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = domain_name,
									spawn = {
										label = "Workspace: " .. domain_name,
										domain = { DomainName = domain_name },
									},
								}),
								inner_pane
							)
							return
						end

						wezterm.emit("smart_workspace_switcher.workspace_switcher.selected", window, id, label)

						-- Check if an existing workspace was selected
						local is_workspace = false
						for _, w in ipairs(mux.get_workspace_names()) do
							if w == id then
								is_workspace = true
								break
							end
						end

						if is_workspace then
							-- Switch to existing workspace
							inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
						else
							-- Zoxide path: create workspace at that cwd
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = label,
									spawn = { label = "Workspace: " .. label, cwd = id },
								}),
								inner_pane
							)
							wezterm.run_child_process({ "cmd", "/c", "zoxide add " .. id })
						end
					end),
				}),
				pane
			)
		end)
	end
end

return M
