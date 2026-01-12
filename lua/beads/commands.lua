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

  -- Find and select task with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindTask", function(opts)
    ui.find_task()
  end, { desc = "Find and select a task using fuzzy finder" })

  -- Find and update task status with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindStatus", function(opts)
    ui.find_task_status()
  end, { desc = "Find and update task status with fuzzy finder" })

  -- Find and update task priority with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindPriority", function(opts)
    ui.find_task_priority()
  end, { desc = "Find and update task priority with fuzzy finder" })

  -- Set fuzzy finder backend
  vim.api.nvim_create_user_command("BeadsSetFinder", function(opts)
    local backend = opts.args
    if backend == "" then
      vim.notify("Usage: :BeadsSetFinder telescope|fzf_lua|builtin", vim.log.levels.ERROR)
      return
    end
    local fuzzy = require("beads.fuzzy")
    fuzzy.set_finder(backend)
    vim.notify("Fuzzy finder backend set to: " .. backend, vim.log.levels.INFO)
  end, {
    desc = "Set preferred fuzzy finder backend (telescope, fzf_lua, or builtin)",
    nargs = 1,
  })

  -- Setup statusline integration
  vim.api.nvim_create_user_command("BeadsStatusline", function(opts)
    local statusline = require("beads.statusline")
    local component = statusline.register_statusline_component()
    vim.notify("Beads statusline component: " .. component, vim.log.levels.INFO)
    vim.notify("Add to your statusline setting: " .. component, vim.log.levels.INFO)
  end, { desc = "Show beads statusline component for use in statusline setting" })

  -- Enable statusline for current window
  vim.api.nvim_create_user_command("BeadsStatuslineEnable", function(opts)
    local statusline = require("beads.statusline")
    statusline.setup({ enabled = true })
    vim.notify("Beads statusline enabled", vim.log.levels.INFO)
  end, { desc = "Enable beads statusline integration" })

  -- Disable statusline for current window
  vim.api.nvim_create_user_command("BeadsStatuslineDisable", function(opts)
    local statusline = require("beads.statusline")
    statusline.setup({ enabled = false })
    vim.notify("Beads statusline disabled", vim.log.levels.INFO)
  end, { desc = "Disable beads statusline integration" })
end

-- Initialize commands on load
M.setup()

return M
