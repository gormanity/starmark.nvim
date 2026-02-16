# Starmark.nvim

## Vision
StarCraft-style marking for Neovim — set marks on file positions with `<leader>m{0-9}`, jump to them with `<leader>{0-9}`.

## Why not Harpoon?
- More intuitive mental model (RTS control groups)
- 10 slots instead of 4
- Persistent per-project storage
- Built-in float UI + optional Telescope integration

## Roadmap
- [x] Core mark storage and manipulation
- [x] Config with sensible defaults
- [x] JSON persistence per project
- [x] Floating window UI
- [ ] Telescope picker integration
- [ ] Mark indicators in signcolumn/statusline
