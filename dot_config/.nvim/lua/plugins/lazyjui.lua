return {
  {
    "mrdwarf7/lazyjui.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "<Leader>jj",
        function()
          require("lazyjui").open()
        end,
      },
    },
    -- the defaults (borderless float, 0.9 x 0.8, `jjui`) are what this config wants
    opts = {},
  },
}
