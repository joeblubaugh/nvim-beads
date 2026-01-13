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

-- Statusline integration for beads plugin

local M = {}

local cli = require("beads.cli")
local utils = require("beads.utils")

-- Cached task stats
local cache = {
  stats = nil,
  last_update = 0,
  update_interval = 5000, -- milliseconds
}

-- Statusline configuration
local config = {
  enabled = false,
  format = nil, -- Custom format function
  highlight = "StatusLine", -- Highlight group
}

--- Get task statistics
--- @return table Task statistics (open, in_progress, closed, total)
local function get_task_stats()
  local now = vim.fn.reltime()[1]
  local elapsed = (now - cache.last_update) * 1000

  -- Return cached stats if fresh
  if cache.stats and elapsed < cache.update_interval then
    return cache.stats
  end

  -- Fetch fresh stats
  local tasks, err = cli.ready()
  if not tasks then
    return {
      open = 0,
      in_progress = 0,
      closed = 0,
      total = 0,
      error = true,
    }
  end

  -- Normalize task list
  local task_list = utils.normalize_response(tasks)

  -- Count tasks by status
  local stats = {
    open = 0,
    in_progress = 0,
    closed = 0,
    total = #task_list,
    error = false,
  }

  for _, task in ipairs(task_list) do
    local status = task.status or "open"
    if status == "in_progress" then
      stats.in_progress = stats.in_progress + 1
    elseif status == "closed" or status == "complete" then
      stats.closed = stats.closed + 1
    else
      stats.open = stats.open + 1
    end
  end

  cache.stats = stats
  cache.last_update = now

  return stats
end

--- Get task count component for statusline
--- @return string Statusline component text
function M.get_task_count()
  local stats = get_task_stats()
  if stats.error or stats.total == 0 then
    return ""
  end
  return string.format("[%d]", stats.total)
end

--- Get task status component for statusline
--- @return string Statusline component with status indicators
function M.get_status_indicator()
  local stats = get_task_stats()
  if stats.error or stats.total == 0 then
    return ""
  end

  local parts = {}
  if stats.open > 0 then
    table.insert(parts, "○" .. stats.open)
  end
  if stats.in_progress > 0 then
    table.insert(parts, "◐" .. stats.in_progress)
  end
  if stats.closed > 0 then
    table.insert(parts, "✓" .. stats.closed)
  end

  if #parts == 0 then
    return ""
  end

  return "[" .. table.concat(parts, " ") .. "]"
end

--- Get priority breakdown component for statusline
--- @return string Statusline component with priority info
function M.get_priority_info()
  local tasks, err = cli.ready()
  if not tasks then
    return ""
  end

  -- Normalize task list
  local task_list = utils.normalize_response(tasks)

  if #task_list == 0 then
    return ""
  end

  -- Count by priority
  local priorities = {
    P1 = 0,
    P2 = 0,
    P3 = 0,
  }

  for _, task in ipairs(task_list) do
    local priority = task.priority or "P2"
    if priorities[priority] then
      priorities[priority] = priorities[priority] + 1
    end
  end

  -- Format as P1:x P2:y P3:z if any exist
  local parts = {}
  for _, p in ipairs({ "P1", "P2", "P3" }) do
    if priorities[p] > 0 then
      table.insert(parts, p .. ":" .. priorities[p])
    end
  end

  if #parts == 0 then
    return ""
  end

  return "[" .. table.concat(parts, " ") .. "]"
end

--- Get beads status component (abbreviated form)
--- @return string Short statusline component
function M.get_status_short()
  local stats = get_task_stats()
  if stats.error or stats.total == 0 then
    return ""
  end

  if stats.in_progress > 0 then
    return string.format("Beads:%d/%d", stats.in_progress, stats.total)
  else
    return string.format("Beads:%d", stats.total)
  end
end

--- Invalidate cache (called when tasks are updated)
function M.invalidate_cache()
  cache.stats = nil
  cache.last_update = 0
end

--- Set custom update interval
--- @param interval integer Milliseconds between cache updates
function M.set_update_interval(interval)
  cache.update_interval = interval
end

--- Setup statusline integration
--- @param opts table Configuration options
function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= false
  config.highlight = opts.highlight or "StatusLine"
  config.format = opts.format
end

--- Get the statusline component (using custom format or default)
--- @return string Statusline component
function M.get_statusline()
  if not config.enabled then
    return ""
  end

  if config.format then
    return config.format()
  end

  -- Default format: short status with indicators
  return M.get_status_short() .. " " .. M.get_status_indicator()
end

--- Build a custom statusline format function
--- @param components table List of component names to include
--- @return function Format function that can be used in statusline
function M.build_format(components)
  components = components or { "short", "indicator" }

  return function()
    local parts = {}
    for _, comp in ipairs(components) do
      local text = ""
      if comp == "count" then
        text = M.get_task_count()
      elseif comp == "short" then
        text = M.get_status_short()
      elseif comp == "indicator" then
        text = M.get_status_indicator()
      elseif comp == "priority" then
        text = M.get_priority_info()
      end

      if text ~= "" then
        table.insert(parts, text)
      end
    end

    if #parts == 0 then
      return ""
    end

    return table.concat(parts, " ")
  end
end

--- Register beads statusline component with vim
--- Creates a custom statusline expression that can be used in &statusline
function M.register_statusline_component()
  vim.fn.statusline_components = vim.fn.statusline_components or {}

  -- Create a global function for use in statusline
  _G.beads_statusline = function()
    return M.get_statusline()
  end

  return "%{luaeval('beads_statusline()')}"
end

--- Get configuration
--- @return table Current configuration
function M.get_config()
  return vim.deepcopy(config)
end

return M
