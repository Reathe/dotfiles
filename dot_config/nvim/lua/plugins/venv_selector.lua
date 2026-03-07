return {
  "linux-cultist/venv-selector.nvim",
  opts = {
    options = {
      enable_default_searches = false,
    },
    search = {
      uv = {
        command = "uv python find",
      },
    },
  },
}
