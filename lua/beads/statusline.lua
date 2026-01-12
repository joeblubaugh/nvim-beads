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

-- Cached task stats
local cache = {
  stats = nil,
  last_update = 0,
  update_interval = 5000, -- milliseconds
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

  -- Handle both array and object responses
  local task_list = {}
  if type(tasks) == "table" then
    if tasks[1] then
      task_list = tasks
    else
      task_list = { tasks }
    end
  end

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

  -- Handle both array and object responses
  local task_list = {}
  if type(tasks) == "table" then
    if tasks[1] then
      task_list = tasks
    else
      task_list = { tasks }
    end
  end

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

return M
