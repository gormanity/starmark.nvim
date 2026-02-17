local helpers = require("tests.helpers")

describe("starmark.ui", function()
  local ui, marks

  before_each(function()
    helpers.reset()
    local config = require("starmark.config")
    config.setup({ notify = false })
    marks = require("starmark.marks")
    ui = require("starmark.ui")
  end)

  describe("format_lines", function()
    it("returns empty message when no marks", function()
      local lines = ui.format_lines()
      assert.equals(1, #lines)
      assert.truthy(lines[1]:find("No marks set"))
    end)

    it("formats marks with slot, file, and line", function()
      marks.set_mark(0, "/home/user/project/foo.lua", 10, 0)
      marks.set_mark(3, "/home/user/project/bar.lua", 42, 5)

      local lines = ui.format_lines()
      assert.equals(2, #lines)
      -- Should contain slot number and line number
      assert.truthy(lines[1]:find("0"))
      assert.truthy(lines[1]:find("10"))
      assert.truthy(lines[2]:find("3"))
      assert.truthy(lines[2]:find("42"))
    end)

    it("sorts marks by slot number", function()
      marks.set_mark(5, "/tmp/b.lua", 50, 0)
      marks.set_mark(1, "/tmp/a.lua", 10, 0)
      marks.set_mark(9, "/tmp/c.lua", 90, 0)

      local lines = ui.format_lines()
      assert.equals(3, #lines)
      -- First line should be slot 1, then 5, then 9
      assert.truthy(lines[1]:find("1"))
      assert.truthy(lines[2]:find("5"))
      assert.truthy(lines[3]:find("9"))
    end)
  end)

  describe("picker_entries", function()
    it("returns empty table when no marks", function()
      local entries = ui.picker_entries()
      assert.equals(0, #entries)
    end)

    it("returns entries sorted by slot", function()
      marks.set_mark(5, "/tmp/b.lua", 50, 3)
      marks.set_mark(1, "/tmp/a.lua", 10, 0)

      local entries = ui.picker_entries()
      assert.equals(2, #entries)
      assert.equals(1, entries[1].slot)
      assert.equals(5, entries[2].slot)
    end)

    it("includes file, line, col, and display in each entry", function()
      marks.set_mark(3, "/home/user/project/foo.lua", 42, 7)

      local entries = ui.picker_entries()
      assert.equals(1, #entries)
      assert.equals(3, entries[1].slot)
      assert.equals("/home/user/project/foo.lua", entries[1].file)
      assert.equals(42, entries[1].line)
      assert.equals(7, entries[1].col)
      assert.is_string(entries[1].display)
      assert.truthy(entries[1].display:find("%[3%]"))
      assert.truthy(entries[1].display:find("42"))
    end)

    it("telescope_entries is an alias for picker_entries", function()
      assert.equals(ui.picker_entries, ui.telescope_entries)
    end)
  end)

  describe("delete_entry", function()
    it("removes a mark from picker_entries", function()
      marks.set_mark(2, "/tmp/a.lua", 10, 0)
      marks.set_mark(5, "/tmp/b.lua", 50, 3)

      ui.delete_entry(2)

      local entries = ui.picker_entries()
      assert.equals(1, #entries)
      assert.equals(5, entries[1].slot)
    end)

    it("persists deletion when persistence is enabled", function()
      local config = require("starmark.config")
      config.setup({ notify = false, persistence = true })
      local persistence = require("starmark.persistence")
      local saved = false
      local orig_save = persistence.save
      persistence.save = function()
        saved = true
      end

      marks.set_mark(0, "/tmp/a.lua", 1, 0)
      ui.delete_entry(0)

      assert.is_true(saved)
      persistence.save = orig_save
    end)

    it("is a no-op for empty slots", function()
      marks.set_mark(1, "/tmp/a.lua", 10, 0)

      ui.delete_entry(7)

      local entries = ui.picker_entries()
      assert.equals(1, #entries)
    end)
  end)
end)
