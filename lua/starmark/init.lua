local M = {}

local config = require("starmark.config")
local marks = require("starmark.marks")
local persistence = require("starmark.persistence")
local signs = require("starmark.signs")
local ui = require("starmark.ui")

---@param slot number 0-9
function M.set_mark(slot)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("starmark: cannot mark unsaved buffer", vim.log.levels.WARN)
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  marks.set_mark(slot, file, pos[1], pos[2])

  local cfg = config.get()
  if cfg.notify.mark then
    local display = vim.fn.fnamemodify(file, ":~:.")
    vim.notify(string.format("starmark: [%d] set at %s:%d", slot, display, pos[1]))
  end

  if cfg.persistence then
    persistence.save()
  end

  signs.update_buf(vim.api.nvim_get_current_buf())
end

---@param slot number 0-9
function M.jump_to_mark(slot)
  local mark = marks.get_mark(slot)
  if not mark then
    local cfg = config.get()
    if cfg.notify.error then
      vim.notify(string.format("starmark: slot [%d] is empty", slot), vim.log.levels.WARN)
    end
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(mark.file))
  vim.api.nvim_win_set_cursor(0, { mark.line, mark.col })

  local cfg = config.get()
  if cfg.notify.jump then
    local display = vim.fn.fnamemodify(mark.file, ":~:.")
    vim.notify(string.format("starmark: jumped to [%d] %s:%d", slot, display, mark.line))
  end
end

---@param slot number? If nil, prompts user
function M.clear_mark(slot)
  if slot then
    marks.clear_mark(slot)
    local cfg = config.get()
    if cfg.notify.mark then
      vim.notify(string.format("starmark: cleared slot [%d]", slot))
    end
    if cfg.persistence then
      persistence.save()
    end
    signs.update_buf(vim.api.nvim_get_current_buf())
    return
  end

  vim.ui.input({ prompt = "Clear mark slot (0-9): " }, function(input)
    if not input then
      return
    end
    local s = tonumber(input)
    if not s or s < 0 or s > 9 then
      local cfg = config.get()
      if cfg.notify.error then
        vim.notify("starmark: invalid slot", vim.log.levels.WARN)
      end
      return
    end
    M.clear_mark(s)
  end)
end

function M.open_ui()
  ui.open()
end

function M.toggle_ui()
  ui.toggle()
end

function M.pick()
  ui.pick()
end

--- Backward compat alias
M.telescope = M.pick

local function setup_keymaps()
  local opts = { noremap = true, silent = true }

  for i = 0, 9 do
    vim.keymap.set("n", "<C-" .. i .. ">", function()
      M.set_mark(i)
    end, vim.tbl_extend("force", opts, { desc = "Starmark: set mark " .. i }))

    vim.keymap.set("n", "<leader>" .. i, function()
      M.jump_to_mark(i)
    end, vim.tbl_extend("force", opts, { desc = "Starmark: jump to mark " .. i }))
  end

  vim.keymap.set("n", "<leader>M", M.pick, vim.tbl_extend("force", opts, { desc = "Starmark: pick mark" }))
  vim.keymap.set("n", "<leader>mx", function()
    M.clear_mark()
  end, vim.tbl_extend("force", opts, { desc = "Starmark: clear mark" }))

  -- Collapse digit keymaps in which-key if available
  local wk_ok, wk = pcall(require, "which-key")
  if wk_ok then
    local hidden = {}
    for i = 0, 9 do
      table.insert(hidden, { "<leader>" .. i, hidden = true })
    end
    wk.add(hidden)
    wk.add({ { "<leader>#", desc = "Starmark: jump to mark #" } })
  end
end

---@param opts table?
function M.setup(opts)
  config.setup(opts)

  local cfg = config.get()

  if cfg.persistence then
    persistence.load()
  end

  if cfg.keymaps then
    setup_keymaps()
  end

  -- User commands
  vim.api.nvim_create_user_command("Starmark", function()
    M.pick()
  end, { desc = "Open Starmark picker" })

  vim.api.nvim_create_user_command("StarmarkPick", function()
    M.pick()
  end, { desc = "Open Starmark picker" })

  vim.api.nvim_create_user_command("StarmarkTelescope", function()
    M.pick()
  end, { desc = "Open Starmark picker (alias for StarmarkPick)" })

  -- Update signs on BufEnter
  if cfg.signs.enabled then
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("starmark_signs", { clear = true }),
      callback = function(ev)
        signs.update_buf(ev.buf)
      end,
    })
  end
end

--- Statusline component showing mark slots for the current buffer.
--- Returns a string like "[0,3,7]" or "" if no marks in this buffer.
---@return string
function M.statusline()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return ""
  end

  local file_marks = marks.get_marks_for_file(filepath)
  local slots = {}
  for slot = 0, 9 do
    if file_marks[slot] then
      table.insert(slots, tostring(slot))
    end
  end

  if #slots == 0 then
    return ""
  end

  return "[" .. table.concat(slots, ",") .. "]"
end

return M
