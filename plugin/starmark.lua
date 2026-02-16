if vim.g.loaded_starmark then
  return
end
vim.g.loaded_starmark = true

-- Starmark is lazy-loaded via require('starmark').setup()
-- This file just prevents double-loading
