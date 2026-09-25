return {
  {
    "AvengeMedia/base46",
    lazy = true,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- Generated on every `omarchy theme set` from ~/.config/omarchy/themed/nvim-base46.lua.tpl (hot reloads itself)
        local omarchy_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/nvim-base46.lua")
        if vim.fn.filereadable(omarchy_theme) == 1 then
          return dofile(omarchy_theme)
        end
        -- "dms" only exists where DankMaterialShell's matugen has generated it (NixOS)
        local dms_theme = vim.fn.stdpath("config") .. "/colors/dms.lua"
        vim.cmd.colorscheme(vim.fn.filereadable(dms_theme) == 1 and "dms" or "base46-tokyonight")
      end,
    },
  },
}
