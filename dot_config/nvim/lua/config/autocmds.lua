-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- remove shada temp files on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local shada_dir = vim.fn.stdpath("data") .. "/shada"
    for _, file in ipairs(vim.fn.glob(shada_dir .. "/*.tmp.*", false, true)) do
      vim.fn.delete(file)
    end
  end,
})
