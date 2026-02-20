# Starmark.nvim - Agent Guidelines

## Project
Neovim plugin for StarCraft-style position marking. Set marks with `Ctrl+{0-9}`, jump with `<leader>{0-9}`.

## Stack
- Lua (Neovim plugin)
- Test framework: plenary.busted

## Commands
- Run tests: `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"`
- Run single test file: `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/starmark/<file>_spec.lua"`

## Conventions
- TDD: write tests first, then implementation
- Each module in `lua/starmark/` has a corresponding `tests/starmark/<module>_spec.lua`
- Use `vim.notify` for user-facing messages (respects `config.notify`)
- Marks are indexed 0-9 (10 slots, like StarCraft control groups)
- Persistence uses JSON, stored per-project in `vim.fn.stdpath("data") .. "/starmark/"`

## Releases
- Cut a release (tag) after user-facing changes land, or when a set of related fixes/features is ready to ship.
