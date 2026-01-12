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

-- Neovim commands for beads plugin

local M = {}
local cli = require("beads.cli")
local ui = require("beads.ui")

--- Setup Neovim commands
function M.setup()
  -- Main beads command - show task list
  vim.api.nvim_create_user_command("Beads", function(opts)
    ui.show_task_list()
  end, { desc = "Show Beads task list" })

  -- Create new task
  vim.api.nvim_create_user_command("BeadsCreate", function(opts)
    local title = opts.args
    if title == "" then
      vim.notify("Task title required", vim.log.levels.ERROR)
      return
    end
    ui.create_task(title)
  end, {
    desc = "Create a new Beads task",
    nargs = "+",
  })

  -- Show task details
  vim.api.nvim_create_user_command("BeadsShow", function(opts)
    local id = opts.args
    if id == "" then
      vim.notify("Task ID required", vim.log.levels.ERROR)
      return
    end
    ui.show_task_detail(id)
  end, {
    desc = "Show details of a Beads task",
    nargs = 1,
  })

  -- Update task
  vim.api.nvim_create_user_command("BeadsUpdate", function(opts)
    local args = vim.split(opts.args, " ")
    if #args < 2 then
      vim.notify("Usage: :BeadsUpdate <id> <field> <value>", vim.log.levels.ERROR)
      return
    end
    local id = args[1]
    local field = args[2]
    local value = table.concat(args, " ", 3)
    ui.update_task(id, field, value)
  end, {
    desc = "Update a Beads task",
    nargs = "+",
  })

  -- Close task
  vim.api.nvim_create_user_command("BeadsClose", function(opts)
    local id = opts.args
    if id == "" then
      vim.notify("Task ID required", vim.log.levels.ERROR)
      return
    end
    ui.close_task(id)
  end, {
    desc = "Close a Beads task",
    nargs = 1,
  })

  -- Sync with remote
  vim.api.nvim_create_user_command("BeadsSync", function(opts)
    ui.sync()
  end, { desc = "Sync with Beads remote" })

  -- Refresh task list
  vim.api.nvim_create_user_command("BeadsRefresh", function(opts)
    ui.refresh_task_list()
  end, { desc = "Refresh Beads task list" })

  -- Filter tasks
  vim.api.nvim_create_user_command("BeadsFilter", function(opts)
    local filter_str = opts.args
    if filter_str == "" then
      vim.notify("Usage: :BeadsFilter priority:P1,status:open,assignee:name", vim.log.levels.ERROR)
      return
    end
    ui.apply_filter_string(filter_str)
    ui.refresh_task_list()
  end, {
    desc = "Filter tasks by priority, status, or assignee",
    nargs = "+",
  })

  -- Clear filters
  vim.api.nvim_create_user_command("BeadsClearFilters", function(opts)
    ui.clear_filters()
    ui.refresh_task_list()
    vim.notify("Filters cleared", vim.log.levels.INFO)
  end, {
    desc = "Clear all active filters",
  })
end

-- Initialize commands on load
M.setup()

return M
