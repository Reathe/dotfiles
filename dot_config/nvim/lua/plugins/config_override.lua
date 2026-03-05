return {
  {
    "folke/snacks.nvim",
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true },
          files = { hidden = true },
        },
      },
      scroll = { enabled = false },
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
