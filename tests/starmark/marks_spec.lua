local helpers = require("tests.helpers")

describe("starmark.marks", function()
  local marks

  before_each(function()
    helpers.reset()
    marks = require("starmark.marks")
  end)

  describe("set_mark", function()
    it("sets a mark in a slot", function()
      marks.set_mark(1, "/tmp/foo.lua", 10, 5)
      local m = marks.get_mark(1)

      assert.is_not_nil(m)
      assert.equals("/tmp/foo.lua", m.file)
      assert.equals(10, m.line)
      assert.equals(5, m.col)
    end)

    it("overwrites existing mark in same slot", function()
      marks.set_mark(1, "/tmp/foo.lua", 10, 5)
      marks.set_mark(1, "/tmp/bar.lua", 20, 0)
      local m = marks.get_mark(1)

      assert.equals("/tmp/bar.lua", m.file)
      assert.equals(20, m.line)
    end)

    it("supports slots 0-9", function()
      for i = 0, 9 do
        marks.set_mark(i, "/tmp/file" .. i .. ".lua", i * 10, 0)
      end

      for i = 0, 9 do
        local m = marks.get_mark(i)
        assert.is_not_nil(m)
        assert.equals("/tmp/file" .. i .. ".lua", m.file)
        assert.equals(i * 10, m.line)
      end
    end)

    it("rejects invalid slot numbers", function()
      assert.has_error(function()
        marks.set_mark(10, "/tmp/foo.lua", 1, 0)
      end)
      assert.has_error(function()
        marks.set_mark(-1, "/tmp/foo.lua", 1, 0)
      end)
    end)
  end)

  describe("get_mark", function()
    it("returns nil for empty slot", function()
      assert.is_nil(marks.get_mark(0))
    end)
  end)

  describe("clear_mark", function()
    it("clears an existing mark", function()
      marks.set_mark(3, "/tmp/foo.lua", 10, 5)
      marks.clear_mark(3)

      assert.is_nil(marks.get_mark(3))
    end)

    it("is a no-op for empty slot", function()
      assert.has_no.errors(function()
        marks.clear_mark(5)
      end)
    end)
  end)

  describe("get_all_marks", function()
    it("returns empty table when no marks set", function()
      local all = marks.get_all_marks()
      assert.equals(0, vim.tbl_count(all))
    end)

    it("returns all set marks", function()
      marks.set_mark(0, "/tmp/a.lua", 1, 0)
      marks.set_mark(5, "/tmp/b.lua", 50, 3)
      local all = marks.get_all_marks()

      assert.equals(2, vim.tbl_count(all))
      assert.is_not_nil(all[0])
      assert.is_not_nil(all[5])
    end)
  end)

  describe("get_marks_for_file", function()
    it("returns empty table when no marks set", function()
      local result = marks.get_marks_for_file("/tmp/foo.lua")
      assert.equals(0, vim.tbl_count(result))
    end)

    it("returns only marks matching the given file", function()
      marks.set_mark(0, "/tmp/foo.lua", 10, 0)
      marks.set_mark(1, "/tmp/bar.lua", 20, 0)
      marks.set_mark(5, "/tmp/foo.lua", 50, 3)

      local result = marks.get_marks_for_file("/tmp/foo.lua")
      assert.equals(2, vim.tbl_count(result))
      assert.is_not_nil(result[0])
      assert.equals(10, result[0].line)
      assert.is_not_nil(result[5])
      assert.equals(50, result[5].line)
      assert.is_nil(result[1])
    end)

    it("returns empty table when no marks match", function()
      marks.set_mark(0, "/tmp/foo.lua", 10, 0)
      local result = marks.get_marks_for_file("/tmp/other.lua")
      assert.equals(0, vim.tbl_count(result))
    end)
  end)

  describe("set_all_marks", function()
    it("restores marks from a table", function()
      local data = {
        [0] = { file = "/tmp/a.lua", line = 1, col = 0 },
        [3] = { file = "/tmp/b.lua", line = 30, col = 5 },
      }
      marks.set_all_marks(data)

      assert.equals("/tmp/a.lua", marks.get_mark(0).file)
      assert.equals("/tmp/b.lua", marks.get_mark(3).file)
      assert.is_nil(marks.get_mark(1))
    end)
  end)
end)
