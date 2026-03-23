-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- remove shada temp files on startup TODO: DOESNT WORK
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local shada_dir = vim.fn.stdpath("data") .. "/shada"
    for _, file in ipairs(vim.fn.glob(shada_dir .. "/*.tmp.*", false, true)) do
      vim.fn.delete(file)
    end
  end,
})

-- auto insert mode for uv.nvim run python
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(event)
    local name = vim.api.nvim_buf_get_name(event.buf)
    if name:match("uv run python") then
      vim.cmd.startinsert()
    end
  end,
})

-- run nushell scripts with <leader>r
vim.api.nvim_create_autocmd("FileType", {
  pattern = "nu",
  callback = function(event)
    vim.keymap.set("n", "<leader>r", function()
      if vim.bo[event.buf].modified then
        vim.cmd.write()
      end

      local path = vim.api.nvim_buf_get_name(event.buf)
      Snacks.terminal.open(
        { "nu", path },
        { cwd = vim.fn.fnamemodify(path, ":p:h"), interactive = true, auto_close = false }
      )
    end, { buffer = event.buf, desc = "Run Nushell Script" })
  end,
})
