return {
  {
    "folke/snacks.nvim",
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
      picker = {
        sources = {
          explorer = {
            auto_close = true,
            hidden = true,
          },
          files = { hidden = true },
          grep = { hidden = true },
        },
        matcher = { frecency = true },
      },
      scroll = { enabled = false },
      image = { enabled = true },
    },
  },
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "super-tab",
      },
      completion = {
        list = {
          selection = { preselect = true, auto_insert = true },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      servers = {
        -- mason builds nil from source, so only auto-install where cargo exists (NixOS)
        nil_ls = { mason = vim.fn.executable("cargo") == 1 },
        powershell_es = {
          settings = {
            powershell = {
              codeFormatting = { Preset = "OTBS" }, -- One True Brace Style
            },
          },
        },
      },
    },
  },
}
