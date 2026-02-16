local M = {}

local config = require("starmark.config")
local marks = require("starmark.marks")

local ns = vim.api.nvim_create_namespace("starmark_signs")

---@param bufnr number
function M.clear_buf(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

---@param bufnr number
function M.update_buf(bufnr)
  local cfg = config.get()
  if not cfg.signs.enabled then
    return
  end

  M.clear_buf(bufnr)

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return
  end

  local file_marks = marks.get_marks_for_file(filepath)
  for slot, mark in pairs(file_marks) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, mark.line - 1, 0, {
      sign_text = tostring(slot),
      sign_hl_group = cfg.signs.hl_group,
    })
  end
end

return M
