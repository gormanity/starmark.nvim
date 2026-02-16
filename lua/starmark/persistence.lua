local M = {}

local config = require("starmark.config")
local marks = require("starmark.marks")

---@param root string
---@return string
function M.project_key(root)
  -- Simple hash: use vim's built-in sha256
  local hash = vim.fn.sha256(root)
  return hash:sub(1, 16)
end

---@return string
function M.detect_project_root()
  local cfg = config.get()
  if cfg.project_root then
    return cfg.project_root
  end

  -- Try git root
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end

  return vim.fn.getcwd()
end

---@return string
local function save_path()
  local cfg = config.get()
  local root = M.detect_project_root()
  local key = M.project_key(root)
  return cfg.marks_path .. "/" .. key .. ".json"
end

function M.save()
  local cfg = config.get()
  local path = save_path()

  -- Ensure directory exists
  vim.fn.mkdir(cfg.marks_path, "p")

  local all = marks.get_all_marks()

  -- Convert numeric keys to strings for JSON compatibility
  local serializable = {}
  for k, v in pairs(all) do
    serializable[tostring(k)] = v
  end

  local json = vim.fn.json_encode(serializable)
  local f = io.open(path, "w")
  if f then
    f:write(json)
    f:close()
  end
end

function M.load()
  local path = save_path()
  local f = io.open(path, "r")
  if not f then
    return
  end

  local content = f:read("*a")
  f:close()

  if not content or content == "" then
    return
  end

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= "table" then
    return
  end

  -- Convert string keys back to numbers
  local numeric = {}
  for k, v in pairs(data) do
    local slot = tonumber(k)
    if slot then
      numeric[slot] = v
    end
  end

  marks.set_all_marks(numeric)
end

return M
