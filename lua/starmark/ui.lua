local M = {}

local config = require("starmark.config")
local marks = require("starmark.marks")
local persistence = require("starmark.persistence")
local signs = require("starmark.signs")

---@return string[]
function M.format_lines()
  local all = marks.get_all_marks()
  if vim.tbl_count(all) == 0 then
    return { "  No marks set. Use Ctrl+{0-9} to set marks." }
  end

  -- Sort by slot number
  local sorted = {}
  for slot = 0, 9 do
    if all[slot] then
      table.insert(sorted, { slot = slot, mark = all[slot] })
    end
  end

  local lines = {}
  for _, entry in ipairs(sorted) do
    local file = vim.fn.fnamemodify(entry.mark.file, ":~:.")
    local line = string.format("  [%d]  %s:%d", entry.slot, file, entry.mark.line)
    table.insert(lines, line)
  end

  return lines
end

---@type number|nil
local float_win = nil
---@type number|nil
local float_buf = nil

function M.close()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, true)
  end
  float_win = nil
  float_buf = nil
end

function M.open()
  M.close()

  local cfg = config.get()
  local lines = M.format_lines()

  float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].bufhidden = "wipe"

  local width = cfg.ui.width
  local height = math.min(cfg.ui.height, #lines + 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  float_win = vim.api.nvim_open_win(float_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = cfg.ui.border,
    title = " Starmark ",
    title_pos = "center",
  })

  -- Keymaps to jump from float
  for i = 0, 9 do
    vim.keymap.set("n", tostring(i), function()
      M.close()
      local starmark = require("starmark")
      starmark.jump_to_mark(i)
    end, { buffer = float_buf, nowait = true })
  end

  -- Delete mark under cursor
  vim.keymap.set("n", "dd", function()
    local line = vim.api.nvim_get_current_line()
    local slot = tonumber(line:match("%[(%d)%]"))
    if slot then
      M.delete_entry(slot)
      M.open()
    end
  end, { buffer = float_buf, nowait = true })

  -- Close on q or Escape
  vim.keymap.set("n", "q", M.close, { buffer = float_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", M.close, { buffer = float_buf, nowait = true })
end

function M.toggle()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    M.close()
  else
    M.open()
  end
end

--- Delete a mark by slot, saving persistence and updating signs.
---@param slot number 0-9
function M.delete_entry(slot)
  marks.clear_mark(slot)
  local cfg = config.get()
  if cfg.persistence then
    persistence.save()
  end
  signs.update_buf(vim.api.nvim_get_current_buf())
end

--- Build a sorted list of picker entry data from current marks.
---@return table[] entries sorted by slot
function M.picker_entries()
  local all = marks.get_all_marks()
  local entries = {}
  for slot = 0, 9 do
    if all[slot] then
      table.insert(entries, {
        slot = slot,
        file = all[slot].file,
        line = all[slot].line,
        col = all[slot].col,
        display = string.format("[%d] %s:%d", slot, vim.fn.fnamemodify(all[slot].file, ":~:."), all[slot].line),
      })
    end
  end
  return entries
end

--- Backward compat alias
M.telescope_entries = M.picker_entries

--- Jump to a picker entry's location.
---@param entry table
local function jump_to_entry(entry)
  vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  vim.api.nvim_win_set_cursor(0, { entry.line, entry.col })
end

--- Telescope picker adapter
local function pick_telescope()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return false
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local entries = M.picker_entries()

  pickers
    .new({}, {
      prompt_title = "Starmark",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
            filename = entry.file,
            lnum = entry.line,
            col = entry.col + 1,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.grep_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            jump_to_entry(selection.value)
          end
        end)
        map({ "i", "n" }, "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            M.delete_entry(selection.value.slot)
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:refresh(finders.new_table({
              results = M.picker_entries(),
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.display,
                  ordinal = entry.display,
                  filename = entry.file,
                  lnum = entry.line,
                  col = entry.col + 1,
                }
              end,
            }), { reset_prompt = false })
          end
        end)
        return true
      end,
    })
    :find()
  return true
end

--- Snacks.nvim picker adapter
local function pick_snacks()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    return false
  end

  local entries = M.picker_entries()
  local items = {}
  for _, entry in ipairs(entries) do
    table.insert(items, {
      text = entry.display,
      file = entry.file,
      pos = { entry.line, entry.col },
      item = entry,
    })
  end

  snacks.picker({
    title = "Starmark",
    items = items,
    confirm = function(picker, item)
      picker:close()
      if item and item.item then
        jump_to_entry(item.item)
      end
    end,
    actions = {
      delete = function(picker, item)
        if item and item.item then
          M.delete_entry(item.item.slot)
          picker:close()
          pick_snacks()
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete", mode = { "i", "n" } },
        },
      },
    },
  })
  return true
end

--- fzf-lua picker adapter
local function pick_fzflua()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return false
  end

  local entries = M.picker_entries()
  local display_list = {}
  local lookup = {}
  for _, entry in ipairs(entries) do
    table.insert(display_list, entry.display)
    lookup[entry.display] = entry
  end

  fzf.fzf_exec(display_list, {
    prompt = "Starmark> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          local entry = lookup[selected[1]]
          if entry then
            jump_to_entry(entry)
          end
        end
      end,
      ["ctrl-d"] = function(selected)
        if selected and selected[1] then
          local entry = lookup[selected[1]]
          if entry then
            M.delete_entry(entry.slot)
          end
        end
      end,
    },
  })
  return true
end

--- Dispatch to the configured picker.
function M.pick()
  local cfg = config.get()
  local picker = cfg.picker or "auto"

  if picker == "builtin" then
    M.open()
    return
  end

  if picker == "telescope" then
    if not pick_telescope() then
      vim.notify("starmark: telescope.nvim not found", vim.log.levels.WARN)
    end
    return
  end

  if picker == "snacks" then
    if not pick_snacks() then
      vim.notify("starmark: snacks.nvim not found", vim.log.levels.WARN)
    end
    return
  end

  if picker == "fzf-lua" then
    if not pick_fzflua() then
      vim.notify("starmark: fzf-lua not found", vim.log.levels.WARN)
    end
    return
  end

  -- auto: try snacks → telescope → fzf-lua → builtin
  if pick_snacks() then return end
  if pick_telescope() then return end
  if pick_fzflua() then return end
  M.open()
end

--- Backward compat alias
M.telescope = M.pick

return M
