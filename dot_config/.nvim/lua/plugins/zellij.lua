return {
  {
    "https://github.com/fresh2dev/zellij.vim",
    lazy = false,
    init = function()
      vim.g.zellij_navigator_no_default_mappings = 1
    end,
    keys = {
      { "<A-h>", "<Cmd>ZellijNavigateLeft!<CR>", mode = "n", silent = true, desc = "Zellij Left" },
      { "<A-j>", "<Cmd>ZellijNavigateDown<CR>", mode = "n", silent = true, desc = "Zellij Down" },
      { "<A-k>", "<Cmd>ZellijNavigateUp<CR>", mode = "n", silent = true, desc = "Zellij Up" },
      { "<A-l>", "<Cmd>ZellijNavigateRight!<CR>", mode = "n", silent = true, desc = "Zellij Right" },
    },
  },
}
