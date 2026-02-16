local helpers = require("tests.helpers")

describe("starmark.signs", function()
  local signs, marks, config

  before_each(function()
    helpers.reset()
    config = require("starmark.config")
    config.setup({ notify = false })
    marks = require("starmark.marks")
    signs = require("starmark.signs")
  end)

  describe("update_buf", function()
    it("places sign extmarks for marks in the current buffer", function()
      local path = helpers.tmpfile("line1\nline2\nline3\nline4\nline5\n")
      vim.cmd("edit " .. path)
      local resolved = vim.api.nvim_buf_get_name(0)

      marks.set_mark(3, resolved, 2, 0)
      marks.set_mark(7, resolved, 4, 0)

      signs.update_buf(vim.api.nvim_get_current_buf())

      local ns = vim.api.nvim_create_namespace("starmark_signs")
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      assert.equals(2, #extmarks)

      -- Extmarks are 0-indexed lines; marks are 1-indexed
      -- Sort by line to get predictable order
      table.sort(extmarks, function(a, b)
        return a[2] < b[2]
      end)

      assert.equals(1, extmarks[1][2]) -- line 2 -> 0-indexed 1
      assert.truthy(extmarks[1][4].sign_text:find("3"))
      assert.equals(3, extmarks[2][2]) -- line 4 -> 0-indexed 3
      assert.truthy(extmarks[2][4].sign_text:find("7"))
    end)

    it("clears previous signs before placing new ones", function()
      local path = helpers.tmpfile("line1\nline2\nline3\n")
      vim.cmd("edit " .. path)
      local resolved = vim.api.nvim_buf_get_name(0)

      marks.set_mark(0, resolved, 1, 0)
      signs.update_buf(vim.api.nvim_get_current_buf())

      marks.clear_mark(0)
      marks.set_mark(1, resolved, 3, 0)
      signs.update_buf(vim.api.nvim_get_current_buf())

      local ns = vim.api.nvim_create_namespace("starmark_signs")
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      assert.equals(1, #extmarks)
      assert.truthy(extmarks[1][4].sign_text:find("1"))
    end)

    it("does nothing when signs are disabled", function()
      config.setup({ notify = false, signs = { enabled = false } })
      signs = require("starmark.signs")

      local path = helpers.tmpfile("line1\nline2\n")
      vim.cmd("edit " .. path)
      local resolved = vim.api.nvim_buf_get_name(0)

      marks.set_mark(0, resolved, 1, 0)
      signs.update_buf(vim.api.nvim_get_current_buf())

      local ns = vim.api.nvim_create_namespace("starmark_signs")
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
      assert.equals(0, #extmarks)
    end)

    it("places no signs when buffer has no marks", function()
      local path = helpers.tmpfile("line1\nline2\n")
      vim.cmd("edit " .. path)

      signs.update_buf(vim.api.nvim_get_current_buf())

      local ns = vim.api.nvim_create_namespace("starmark_signs")
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
      assert.equals(0, #extmarks)
    end)
  end)

  describe("clear_buf", function()
    it("removes all sign extmarks from a buffer", function()
      local path = helpers.tmpfile("line1\nline2\n")
      vim.cmd("edit " .. path)
      local resolved = vim.api.nvim_buf_get_name(0)

      marks.set_mark(0, resolved, 1, 0)
      signs.update_buf(vim.api.nvim_get_current_buf())
      signs.clear_buf(vim.api.nvim_get_current_buf())

      local ns = vim.api.nvim_create_namespace("starmark_signs")
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
      assert.equals(0, #extmarks)
    end)
  end)
end)
