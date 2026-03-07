-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- floating terminal
---@module "snacks"
vim.keymap.set({ "n", "t" }, "<C-_>", function()
  Snacks.terminal.toggle()
end, { desc = "Toggle Terminal" })
