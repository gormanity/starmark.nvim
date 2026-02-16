local M = {}

--- Reset starmark state between tests
function M.reset()
  package.loaded["starmark"] = nil
  package.loaded["starmark.config"] = nil
  package.loaded["starmark.marks"] = nil
  package.loaded["starmark.persistence"] = nil
  package.loaded["starmark.ui"] = nil
  package.loaded["starmark.signs"] = nil
end

--- Create a temporary file with optional content
---@param content string?
---@return string path
function M.tmpfile(content)
  local path = vim.fn.tempname() .. ".lua"
  if content then
    local f = io.open(path, "w")
    f:write(content)
    f:close()
  else
    vim.fn.writefile({}, path)
  end
  return path
end

return M
