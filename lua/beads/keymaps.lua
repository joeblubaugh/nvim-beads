-- Copyright 2026 Joe Blubaugh
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

  -- Filter tasks
  vim.keymap.set("n", "<leader>bf", ":BeadsFilter ", vim.tbl_extend("force", opts, { desc = "Beads: Filter" }))

  -- Clear filters
  vim.keymap.set("n", "<leader>bF", ":BeadsClearFilters<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Clear Filters" }))

  -- Fuzzy find task
  vim.keymap.set("n", "<leader>bt", ":BeadsFindTask<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Find Task" }))

  -- Fuzzy update status
  vim.keymap.set("n", "<leader>bS", ":BeadsFindStatus<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Find Status" }))

  -- Fuzzy update priority
  vim.keymap.set("n", "<leader>bP", ":BeadsFindPriority<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Find Priority" }))

  -- Statusline toggle
  vim.keymap.set("n", "<leader>bsl", ":BeadsStatusline<CR>", vim.tbl_extend("force", opts, { desc = "Beads: Show Statusline Component" }))
end

return M
