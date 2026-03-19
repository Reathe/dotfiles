local pick_chezmoi_files

local function get_managed_files()
  local raw = vim.fn.system("chezmoi list --path-style all --format json --include files --exclude externals")
  if vim.v.shell_error ~= 0 then
    vim.notify(raw, vim.log.levels.ERROR, { title = "chezmoi" })
    return nil
  end

  return vim.json.decode(raw)
end

local function get_source_dir(managed_files)
  local first = managed_files[next(managed_files)]
  if not first then
    return nil
  end

  return first.sourceAbsolute:sub(1, #first.sourceAbsolute - #first.sourceRelative)
end

local function build_picker_items(managed_files, source_files)
  local items = {}
  local managed_source_files = {}

  for _, entry in pairs(managed_files) do
    managed_source_files[entry.sourceAbsolute] = true
    items[#items + 1] = { text = entry.absolute, file = entry.absolute, managed = true }
  end

  for _, file in ipairs(source_files) do
    if not managed_source_files[file] then
      items[#items + 1] = { text = file, file = file, managed = false }
    end
  end

  return items
end

function pick_chezmoi_files()
  local managed_files = get_managed_files()
  if not managed_files then
    return
  end

  local source_dir = get_source_dir(managed_files)
  if not source_dir then
    vim.notify("No chezmoi-managed files found", vim.log.levels.WARN, { title = "chezmoi" })
    return
  end

  local source_files =
    vim.fn.systemlist("rg --files " .. vim.fn.shellescape(source_dir) .. " --path-separator=/ --hidden -g !.git")
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to list chezmoi source files", vim.log.levels.ERROR, { title = "chezmoi" })
    return
  end

  local items = build_picker_items(managed_files, source_files)
  local chezmoi = require("chezmoi.commands")

  Snacks.picker.pick({
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
        return
      end

      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
    end,
  })
end

local function build_keys(_, keys)
  for _, key in ipairs(keys) do
    if key[1] == "<leader>sz" then
      key[1] = "<leader>sZ"
    end
  end

  keys[#keys + 1] = {
    "<leader>sz",
    pick_chezmoi_files,
    desc = "Chezmoi (managed + source)",
  }

  return keys
end

return {
  {
    "xvzc/chezmoi.nvim",
    keys = build_keys,
    opts = { watch = true },
  },
}
