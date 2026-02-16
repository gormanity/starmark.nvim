local helpers = require("tests.helpers")

describe("starmark.persistence", function()
  local persistence, marks, config
  local test_dir

  before_each(function()
    helpers.reset()
    test_dir = vim.fn.tempname() .. "_starmark_test"
    vim.fn.mkdir(test_dir, "p")

    config = require("starmark.config")
    config.setup({ marks_path = test_dir, project_root = "/tmp/test_project" })

    marks = require("starmark.marks")
    persistence = require("starmark.persistence")
  end)

  after_each(function()
    vim.fn.delete(test_dir, "rf")
  end)

  describe("project_key", function()
    it("generates a consistent key for a project root", function()
      local key1 = persistence.project_key("/tmp/test_project")
      local key2 = persistence.project_key("/tmp/test_project")
      assert.equals(key1, key2)
    end)

    it("generates different keys for different roots", function()
      local key1 = persistence.project_key("/tmp/project_a")
      local key2 = persistence.project_key("/tmp/project_b")
      assert.is_not.equals(key1, key2)
    end)
  end)

  describe("save and load", function()
    it("round-trips marks through JSON", function()
      marks.set_mark(0, "/tmp/a.lua", 1, 0)
      marks.set_mark(5, "/tmp/b.lua", 50, 3)

      persistence.save()

      -- reset marks and reload
      helpers.reset()
      config = require("starmark.config")
      config.setup({ marks_path = test_dir, project_root = "/tmp/test_project" })
      marks = require("starmark.marks")
      persistence = require("starmark.persistence")

      persistence.load()

      local m0 = marks.get_mark(0)
      local m5 = marks.get_mark(5)

      assert.is_not_nil(m0)
      assert.equals("/tmp/a.lua", m0.file)
      assert.equals(1, m0.line)

      assert.is_not_nil(m5)
      assert.equals("/tmp/b.lua", m5.file)
      assert.equals(50, m5.line)
    end)

    it("handles no existing save file gracefully", function()
      assert.has_no.errors(function()
        persistence.load()
      end)
    end)

    it("handles empty marks", function()
      persistence.save()

      helpers.reset()
      config = require("starmark.config")
      config.setup({ marks_path = test_dir, project_root = "/tmp/test_project" })
      marks = require("starmark.marks")
      persistence = require("starmark.persistence")

      persistence.load()
      assert.equals(0, vim.tbl_count(marks.get_all_marks()))
    end)
  end)

  describe("detect_project_root", function()
    it("returns configured root if set", function()
      local root = persistence.detect_project_root()
      assert.equals("/tmp/test_project", root)
    end)

    it("falls back to cwd when no root configured and no git", function()
      config.setup({ marks_path = test_dir, project_root = nil })
      local root = persistence.detect_project_root()
      assert.is_string(root)
      assert.is_not.equals("", root)
    end)
  end)
end)
