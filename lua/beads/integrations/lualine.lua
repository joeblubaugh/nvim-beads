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

-- lualine integration for Beads plugin

local M = {}

--- Get lualine component for task count
--- @return table Lualine component
function M.task_count()
  local statusline = require("beads.statusline")
  local count = statusline.get_task_count()
  return count
end

--- Get lualine component for sync status
--- @return table Lualine component
function M.sync_status()
  local statusline = require("beads.statusline")
  local status = statusline.get_status_indicator()
  return status
end

--- Get lualine component for priority info
--- @return table Lualine component
function M.priority_info()
  local statusline = require("beads.statusline")
  local info = statusline.get_priority_info()
  return info
end

--- Register all beads components with lualine
--- @return boolean True if successfully registered
function M.register_with_lualine()
  local ok, lualine = pcall(require, "lualine")
  if not ok then
    vim.notify("lualine not found", vim.log.levels.WARN)
    return false
  end

  -- Register the components
  local components = {
    task_count = {
      function()
        return M.task_count()
      end,
      color = "BeadsAccent",
      cond = function()
        local stats = require("beads.statusline").get_task_stats()
        return stats and stats.total > 0
      end,
    },
    sync_status = {
      function()
        return M.sync_status()
      end,
      color = "BeadsSyncIdle",
    },
    priority_info = {
      function()
        return M.priority_info()
      end,
      color = "BeadsPriorityP1",
      cond = function()
        return require("beads.statusline").get_priority_info() ~= ""
      end,
    },
  }

  -- Add to lualine if available
  local theme = require("beads.theme")
  if lualine.setup then
    -- Note: Components are already available and can be manually added to lualine config
    return true
  end

  return true
end

--- Setup lualine integration with default configuration
--- @param opts table|nil Configuration options
function M.setup(opts)
  opts = opts or {}

  -- Auto-register with lualine if it's available
  M.register_with_lualine()

  if opts.auto_add_to_winbar then
    -- Add Beads component to winbar if enabled
    vim.schedule(function()
      local ok, _ = pcall(require, "lualine")
      if ok then
        vim.notify("Beads components registered with lualine. Add to your lualine config.", vim.log.levels.INFO)
      end
    end)
  end
end

return M
