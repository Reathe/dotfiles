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
        -- "dms" only exists where DankMaterialShell's matugen has generated it (NixOS)
        local dms_theme = vim.fn.stdpath("config") .. "/colors/dms.lua"
        vim.cmd.colorscheme(vim.fn.filereadable(dms_theme) == 1 and "dms" or "base46-tokyonight")
      end,
    },
  },
}
