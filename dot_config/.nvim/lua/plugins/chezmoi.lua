return {
  {
    "xvzc/chezmoi.nvim",
    keys = function(_, keys)
      for _, key in ipairs(keys) do
        if key[1] == "<leader>sz" then
          key[1] = "<leader>sZ"
        end
      end
      return keys
    end,
  },
  {
    "xvzc/chezmoi.nvim",
    keys = {
      {
        "<leader>sz",
        function()
          local chezmoi = require("chezmoi.commands")

          -- Managed files
          local raw = vim.fn.system("chezmoi list --path-style all --format json --include files --exclude externals")
          local managed_all = vim.json.decode(raw) -- { [relpath]: { absolute, sourceAbsolute, sourceRelative } }

          -- computing chezmoi source_dir and searching all files in it
          -- source_dir is managed_all[1].sourceAbsolute - managed_all[1].sourceRelative
          local first = managed_all[next(managed_all)]
          local source_dir = first.sourceAbsolute:sub(1, #first.sourceAbsolute - #first.sourceRelative)
          local all_source_files = vim.fn.systemlist(
            "rg --files " .. vim.fn.shellescape(source_dir) .. " --path-separator=/ --hidden -g !.git"
          )

          local items = {}
          local managed_source_set = {}

          -- adding managed files to picker
          for _, entry in pairs(managed_all) do
            managed_source_set[entry.sourceAbsolute] = true
            table.insert(items, { text = entry.absolute, file = entry.absolute, managed = true })
          end

          -- adding source files that are not managed to picker
          for _, f in ipairs(all_source_files) do
            if not managed_source_set[f] then
              table.insert(items, { text = f, file = f, managed = false })
            end
          end

          ---@module "snacks"
          ---@type snacks.picker.Config
          local opts = {
            title = "Chezmoi",
            items = items,
            format = "file",
            confirm = function(picker, item)
              picker:close()
              if item.managed then
                chezmoi.edit({
                  targets = { item.file },
                  args = { "--watch" },
                })
              else
                vim.cmd("edit " .. vim.fn.fnameescape(item.file))
              end
            end,
          }
          Snacks.picker.pick(opts)
        end,
        desc = "Chezmoi (managed + source)",
      },
    },
    opts = { watch = true },
  },
}
