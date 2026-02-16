local helpers = require("tests.helpers")

describe("starmark.config", function()
  before_each(function()
    helpers.reset()
  end)

  it("returns default config", function()
    local config = require("starmark.config")
    local defaults = config.get()

    assert.is_true(defaults.persistence)
    assert.is_true(defaults.keymaps)
    assert.is_true(defaults.notify)
    assert.equals("rounded", defaults.ui.border)
    assert.equals(60, defaults.ui.width)
    assert.equals(12, defaults.ui.height)
    assert.is_nil(defaults.project_root)
    assert.is_string(defaults.marks_path)
    assert.is_true(defaults.signs.enabled)
    assert.equals("DiagnosticInfo", defaults.signs.hl_group)
    assert.equals("auto", defaults.picker)
  end)

  it("merges user overrides", function()
    local config = require("starmark.config")
    config.setup({ persistence = false, ui = { width = 80 } })
    local cfg = config.get()

    assert.is_false(cfg.persistence)
    assert.equals(80, cfg.ui.width)
    -- non-overridden values remain default
    assert.equals("rounded", cfg.ui.border)
    assert.equals(12, cfg.ui.height)
    assert.is_true(cfg.keymaps)
  end)

  it("handles empty user config", function()
    local config = require("starmark.config")
    config.setup({})
    local cfg = config.get()

    assert.is_true(cfg.persistence)
    assert.is_true(cfg.keymaps)
  end)

  it("handles nil user config", function()
    local config = require("starmark.config")
    config.setup()
    local cfg = config.get()

    assert.is_true(cfg.persistence)
  end)
end)
