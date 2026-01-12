-- Keymaps for beads plugin

local M = {}

--- Setup default keymaps
function M.setup()
  local opts = { noremap = true, silent = true }

  -- Show task list
  vim.keymap.set("n", "<leader>bd", ":Beads<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Show task list" }))

  -- Create new task
  vim.keymap.set("n", "<leader>bc", ":BeadsCreate ", vim.tbl_extend("force", opts, { desc = "Beads: Create task" }))

  -- Sync tasks
  vim.keymap.set("n", "<leader>bs", ":BeadsSync<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Sync" }))

  -- Refresh task list
  vim.keymap.set("n", "<leader>br", ":BeadsRefresh<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Refresh" }))
end

return M
