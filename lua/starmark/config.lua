local M = {}

local defaults = {
  persistence = true,
  project_root = nil,
  marks_path = vim.fn.stdpath("data") .. "/starmark",
  keymaps = true,
  notify = {
    mark = true,
    jump = true,
    error = true,
  },
  ui = {
    width = 60,
    height = 12,
    border = "rounded",
  },
  picker = "auto",
  signs = {
    enabled = true,
    hl_group = "DiagnosticInfo",
  },
}

local current = nil

local function deep_merge(base, override)
  local result = vim.deepcopy(base)
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

function M.setup(opts)
  opts = opts or {}
  -- Backward compat: expand boolean notify to table
  if type(opts.notify) == "boolean" then
    local val = opts.notify
    opts.notify = { mark = val, jump = val, error = val }
  end
  current = deep_merge(defaults, opts)
end

function M.get()
  if not current then
    current = vim.deepcopy(defaults)
  end
  return current
end

return M
