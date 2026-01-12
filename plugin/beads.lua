-- Beads plugin entry point
-- This file is loaded automatically by Neovim

if vim.fn.has("nvim-0.5") == 0 then
  vim.notify("beads requires Neovim >= 0.5", vim.log.levels.ERROR)
  return
end

-- Avoid loading the plugin twice
if vim.g.loaded_beads == 1 then
  return
end
vim.g.loaded_beads = 1

-- Initialize beads plugin with defaults
require("beads").setup()
