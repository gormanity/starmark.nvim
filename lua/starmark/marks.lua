local M = {}

---@type table<number, {file: string, line: number, col: number}>
local slots = {}

local function validate_slot(slot)
  if type(slot) ~= "number" or slot < 0 or slot > 9 then
    error("starmark: slot must be 0-9, got " .. tostring(slot))
  end
end

---@param slot number 0-9
---@param file string absolute file path
---@param line number 1-indexed line number
---@param col number 0-indexed column
function M.set_mark(slot, file, line, col)
  validate_slot(slot)
  slots[slot] = { file = file, line = line, col = col }
end

---@param slot number 0-9
---@return {file: string, line: number, col: number}|nil
function M.get_mark(slot)
  validate_slot(slot)
  return slots[slot]
end

---@param slot number 0-9
function M.clear_mark(slot)
  validate_slot(slot)
  slots[slot] = nil
end

---@return table<number, {file: string, line: number, col: number}>
function M.get_all_marks()
  return vim.deepcopy(slots)
end

---@param filepath string absolute file path
---@return table<number, {file: string, line: number, col: number}>
function M.get_marks_for_file(filepath)
  local result = {}
  for slot, mark in pairs(slots) do
    if mark.file == filepath then
      result[slot] = mark
    end
  end
  return result
end

---@param data table<number, {file: string, line: number, col: number}>
function M.set_all_marks(data)
  slots = {}
  for k, v in pairs(data) do
    local slot = tonumber(k)
    if slot and slot >= 0 and slot <= 9 then
      slots[slot] = { file = v.file, line = v.line, col = v.col }
    end
  end
end

return M
