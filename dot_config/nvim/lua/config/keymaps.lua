-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
---@module "lazyvim"
---@module "snacks"

-- floating terminal
vim.keymap.set({ "n", "t" }, "<C-/>", function()
  -- Evaluate root from the current (non-terminal) buf when in normal mode,
  -- but always toggle the terminal keyed to that same root path.
  -- Using an explicit id means toggle finds the same instance regardless of
  -- what buffer is focused when the keymap fires.
  local root = vim.bo.buftype == "terminal" and vim.g._snacks_term_root -- reuse last known root
    or LazyVim.root()
    or vim.uv.cwd()
  vim.g._snacks_term_root = root
  Snacks.terminal.toggle(nil, { cwd = root, id = "main_" .. root })
end, { desc = "Toggle Terminal (Root Dir)" })
-- needed on windows
vim.keymap.set({ "n", "t" }, "<C-_>", "<C-/>", { desc = "Toggle Terminal (Root Dir)", remap = true })
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
