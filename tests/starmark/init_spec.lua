local helpers = require("tests.helpers")

describe("starmark notifications", function()
  local notifications

  before_each(function()
    helpers.reset()
    notifications = {}
    -- Intercept vim.notify
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end
  end)

  local function setup_with_notify(notify_opts)
    local config = require("starmark.config")
    config.setup({ notify = notify_opts, keymaps = false, persistence = false, signs = { enabled = false } })
  end

  local function open_tmpfile()
    local path = helpers.tmpfile("-- test")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return path
  end

  describe("set_mark", function()
    it("notifies when notify.mark = true", function()
      setup_with_notify({ mark = true })
      open_tmpfile()

      local starmark = require("starmark")
      starmark.set_mark(0)

      assert.equals(1, #notifications)
      assert.truthy(notifications[1].msg:find("set at"))
    end)

    it("does not notify when notify.mark = false", function()
      setup_with_notify({ mark = false })
      open_tmpfile()

      local starmark = require("starmark")
      starmark.set_mark(0)

      assert.equals(0, #notifications)
    end)
  end)

  describe("jump_to_mark", function()
    it("notifies on success when notify.jump = true", function()
      setup_with_notify({ jump = true })
      open_tmpfile()

      local marks = require("starmark.marks")
      local file = vim.api.nvim_buf_get_name(0)
      marks.set_mark(1, file, 1, 0)

      local starmark = require("starmark")
      starmark.jump_to_mark(1)

      assert.equals(1, #notifications)
      assert.truthy(notifications[1].msg:find("jumped to"))
    end)

    it("does not notify on success when notify.jump = false", function()
      setup_with_notify({ jump = false })
      open_tmpfile()

      local marks = require("starmark.marks")
      local file = vim.api.nvim_buf_get_name(0)
      marks.set_mark(1, file, 1, 0)

      local starmark = require("starmark")
      starmark.jump_to_mark(1)

      assert.equals(0, #notifications)
    end)

    it("notifies on empty slot when notify.error = true", function()
      setup_with_notify({ error = true })

      local starmark = require("starmark")
      starmark.jump_to_mark(9)

      assert.equals(1, #notifications)
      assert.truthy(notifications[1].msg:find("empty"))
    end)

    it("does not notify on empty slot when notify.error = false", function()
      setup_with_notify({ error = false })

      local starmark = require("starmark")
      starmark.jump_to_mark(9)

      assert.equals(0, #notifications)
    end)
  end)

  describe("clear_mark", function()
    it("notifies when notify.mark = true", function()
      setup_with_notify({ mark = true })

      local marks = require("starmark.marks")
      local path = open_tmpfile()
      marks.set_mark(0, path, 1, 0)

      local starmark = require("starmark")
      starmark.clear_mark(0)

      assert.equals(1, #notifications)
      assert.truthy(notifications[1].msg:find("cleared"))
    end)

    it("does not notify when notify.mark = false", function()
      setup_with_notify({ mark = false })

      local marks = require("starmark.marks")
      local path = open_tmpfile()
      marks.set_mark(0, path, 1, 0)

      local starmark = require("starmark")
      starmark.clear_mark(0)

      assert.equals(0, #notifications)
    end)
  end)
end)
