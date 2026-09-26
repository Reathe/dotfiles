-- Niri-inspired keybindings for Omarchy/Hyprland.
-- Source of truth: dot_config/niri/dms/.binds.kdl (NixOS/DMS), adapted for Hyprland tiling.

-- See current bindings:
--   omarchy menu keybindings --print

local function unbind_all(keys)
  for _, key in ipairs(keys) do
    hl.unbind(key)
  end
end

----------------------------------------------------------------------------
-- Free keys that conflict with the Niri-style map
----------------------------------------------------------------------------

unbind_all({
  -- focus / move letters
  "SUPER + J", -- was: toggle split
  "SUPER + K", -- was: keybindings menu
  "SUPER + L", -- was: workspace layout toggle
  "SUPER + T", -- was: toggle float
  "SUPER + W", -- was: close window
  "SUPER + F", -- was: fullscreen
  "SUPER + SHIFT + F", -- was: file manager

  -- move uses Ctrl (was Omarchy utilities / group focus)
  "SUPER + CTRL + H", -- was: hardware menu
  "SUPER + CTRL + L", -- was: lock
  "SUPER + CTRL + K", -- was: herdr keybindings
  "SUPER + CTRL + I", -- was: idle lock toggle
  "SUPER + CTRL + LEFT", -- was: group focus left
  "SUPER + CTRL + RIGHT", -- was: group focus right

  -- wheel: per-monitor workspaces (was e+1 / e-1)
  "SUPER + mouse_down",
  "SUPER + mouse_up",

  -- Shift+Left/Right move the column (was: swap window)
  "SUPER + SHIFT + LEFT",
  "SUPER + SHIFT + RIGHT",

  -- expand column (was: tiled full screen)
  "SUPER + CTRL + F",

  -- resize: rebind to Niri grow/shrink semantics
  "SUPER + code:20",
  "SUPER + code:21",
  "SUPER + SHIFT + code:20",
  "SUPER + SHIFT + code:21",
  "SUPER + ALT + code:20",
  "SUPER + ALT + code:21",
  "SUPER + SHIFT + ALT + code:20",
  "SUPER + SHIFT + ALT + code:21",
  "SUPER + CTRL + code:20",
  "SUPER + CTRL + code:21",
  "SUPER + CTRL + SHIFT + code:20",
  "SUPER + CTRL + SHIFT + code:21",

  -- keybindings cheatsheet (was passwords)
  "SUPER + SHIFT + SLASH",

  -- file manager cwd (was email webapp)
  "SUPER + SHIFT + E",
})

----------------------------------------------------------------------------
-- Apps / window chrome
----------------------------------------------------------------------------

o.bind("SUPER + T", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + SHIFT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + SHIFT + E", "File manager (cwd)", { omarchy = "nautilus-cwd" })

-- Maximize ≈ niri maximize-column; Shift+F ≈ niri fullscreen-window
o.bind("SUPER + F", "Maximize window", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + SHIFT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Tabbed column ≈ Hyprland group
o.bind("SUPER + W", "Toggle window grouping", hl.dsp.group.toggle())

-- Lock (niri: Super+Alt+L). Idle toggle rehomed off Ctrl+I.
o.bind("SUPER + ALT + L", "Lock system", "omarchy-system-lock")
o.bind_toggle("SUPER + CTRL + ALT + I", "Toggle locking on idle", "idle")

-- Hardware menu rehomed off Ctrl+H
o.bind("SUPER + CTRL + ALT + H", "Hardware menu", "omarchy-menu toggle hardware")

-- Cheatsheet (niri: Mod+Shift+/)
o.bind("SUPER + SHIFT + SLASH", "Keybindings", "omarchy-menu-keybindings")

----------------------------------------------------------------------------
-- Focus (niri: Mod+HJKL / arrows)
----------------------------------------------------------------------------

o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))
-- arrows already bound by Omarchy defaults; leave them

----------------------------------------------------------------------------
-- Move in layout (niri: Mod+Shift+H/L move column, Mod+Shift+J/K move window)
-- Up/down arrows keep Omarchy's default Super+Shift+arrow swap.
----------------------------------------------------------------------------

o.bind("SUPER + SHIFT + H", "Move column left", hl.dsp.layout("swapcol l"))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move column right", hl.dsp.layout("swapcol r"))
o.bind("SUPER + SHIFT + LEFT", "Move column left", hl.dsp.layout("swapcol l"))
o.bind("SUPER + SHIFT + RIGHT", "Move column right", hl.dsp.layout("swapcol r"))

----------------------------------------------------------------------------
-- Monitors (niri: Mod+Ctrl focus, Mod+Shift+Ctrl move)
----------------------------------------------------------------------------

o.bind("SUPER + CTRL + H", "Focus left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + CTRL + J", "Focus down monitor", hl.dsp.focus({ monitor = "d" }))
o.bind("SUPER + CTRL + K", "Focus up monitor", hl.dsp.focus({ monitor = "u" }))
o.bind("SUPER + CTRL + L", "Focus right monitor", hl.dsp.focus({ monitor = "r" }))
o.bind("SUPER + CTRL + LEFT", "Focus left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + CTRL + DOWN", "Focus down monitor", hl.dsp.focus({ monitor = "d" }))
o.bind("SUPER + CTRL + UP", "Focus up monitor", hl.dsp.focus({ monitor = "u" }))
o.bind("SUPER + CTRL + RIGHT", "Focus right monitor", hl.dsp.focus({ monitor = "r" }))

-- Move focused window to adjacent monitor, focus follows (niri move-column-to-monitor)
o.bind("SUPER + SHIFT + CTRL + H", "Move window to left monitor", hl.dsp.window.move({ monitor = "l", follow = true }))
o.bind("SUPER + SHIFT + CTRL + J", "Move window to down monitor", hl.dsp.window.move({ monitor = "d", follow = true }))
o.bind("SUPER + SHIFT + CTRL + K", "Move window to up monitor", hl.dsp.window.move({ monitor = "u", follow = true }))
o.bind("SUPER + SHIFT + CTRL + L", "Move window to right monitor", hl.dsp.window.move({ monitor = "r", follow = true }))
o.bind("SUPER + SHIFT + CTRL + LEFT", "Move window to left monitor", hl.dsp.window.move({ monitor = "l", follow = true }))
o.bind("SUPER + SHIFT + CTRL + DOWN", "Move window to down monitor", hl.dsp.window.move({ monitor = "d", follow = true }))
o.bind("SUPER + SHIFT + CTRL + UP", "Move window to up monitor", hl.dsp.window.move({ monitor = "u", follow = true }))
o.bind("SUPER + SHIFT + CTRL + RIGHT", "Move window to right monitor", hl.dsp.window.move({ monitor = "r", follow = true }))

----------------------------------------------------------------------------
-- Workspaces (niri: Mod+U/I, Mod+Ctrl+U/I to move, Mod+Shift+N via Omarchy default)
----------------------------------------------------------------------------

-- m+1 / m-1 stay on the focused monitor, like niri's per-monitor workspaces
o.bind("SUPER + U", "Workspace down", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + I", "Workspace up", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + Page_Down", "Workspace down", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + Page_Up", "Workspace up", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + mouse_down", "Workspace down", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + mouse_up", "Workspace up", hl.dsp.focus({ workspace = "m-1" }))

o.bind("SUPER + CTRL + U", "Move window to workspace down", hl.dsp.window.move({ workspace = "m+1" }))
o.bind("SUPER + CTRL + I", "Move window to workspace up", hl.dsp.window.move({ workspace = "m-1" }))
o.bind("SUPER + CTRL + Page_Down", "Move window to workspace down", hl.dsp.window.move({ workspace = "m+1" }))
o.bind("SUPER + CTRL + Page_Up", "Move window to workspace up", hl.dsp.window.move({ workspace = "m-1" }))
o.bind("SUPER + CTRL + mouse_down", "Move window to workspace down", hl.dsp.window.move({ workspace = "m+1" }))
o.bind("SUPER + CTRL + mouse_up", "Move window to workspace up", hl.dsp.window.move({ workspace = "m-1" }))

----------------------------------------------------------------------------
-- Columns / resize (niri: Mod+-/= column width, Mod+Shift+-/= window height)
-- Needs the scrolling layout (looknfeel.lua). Width is per column, as a
-- fraction of the screen, so it never depends on the window's position.
-- code:20 = minus, code:21 = equal (layout-independent)
----------------------------------------------------------------------------

o.bind("SUPER + code:20", "Shrink column width", hl.dsp.layout("colresize -0.1"))
o.bind("SUPER + code:21", "Grow column width", hl.dsp.layout("colresize +0.1"))
o.bind("SUPER + ALT + code:20", "Shrink column width a little", hl.dsp.layout("colresize -0.05"))
o.bind("SUPER + ALT + code:21", "Grow column width a little", hl.dsp.layout("colresize +0.05"))
o.bind("SUPER + CTRL + code:20", "Shrink column width a lot", hl.dsp.layout("colresize -0.25"))
o.bind("SUPER + CTRL + code:21", "Grow column width a lot", hl.dsp.layout("colresize +0.25"))

-- Height of a window stacked in a column
o.bind("SUPER + SHIFT + code:20", "Shrink height", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Grow height", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:20", "Shrink height a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:21", "Grow height a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:20", "Shrink height a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:21", "Grow height a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

-- niri: Mod+R preset widths, Mod+Ctrl+F expand to available width
o.bind("SUPER + R", "Cycle preset column width", hl.dsp.layout("colresize +conf"))
o.bind("SUPER + CTRL + F", "Expand column to available width", hl.dsp.layout("fit expand"))

-- niri: Mod+[ / Mod+] consume-or-expel, Mod+. expel
-- code:34 = bracketleft, code:35 = bracketright, code:60 = period
o.bind("SUPER + code:34", "Consume or expel window left", hl.dsp.layout("consume_or_expel prev"))
o.bind("SUPER + code:35", "Consume or expel window right", hl.dsp.layout("consume_or_expel next"))
o.bind("SUPER + code:60", "Expel window into its own column", hl.dsp.layout("expel"))
