return {
  {
    "DrKJeff16/wezterm-types",
    version = false,
  },
  {
    "folke/lazydev.nvim",
    dependencies = { "DrKJeff16/wezterm-types" },
    ---@module 'lazydev'
    ---@type lazydev.Config
    opts = {
      library = {
        -- Load the wezterm types when the `wezterm` module is required
        -- Needs `DrKJeff16/wezterm-types` to be installed
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
  },
  {
    -- this is needed to fix lazydev not loading until typing require(...)
    "neovim/nvim-lspconfig",
    dependencies = { "folke/lazydev.nvim" }, -- Ensure lazydev loads first
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = { runtime = { pathStrict = false } },
          },
        },
      },
    },
  },
}
