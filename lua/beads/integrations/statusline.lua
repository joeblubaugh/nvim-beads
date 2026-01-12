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

-- Statusline integration module for custom statusline support

local M = {}

local statusline = require("beads.statusline")

--- Get task count for statusline
--- @return number Total number of tasks
function M.beads_task_count()
  local stats = statusline.get_task_stats()
  return stats and stats.total or 0
end

--- Get open task count
--- @return number Number of open tasks
function M.beads_open_count()
  local stats = statusline.get_task_stats()
  return stats and stats.open or 0
end

--- Get in-progress task count
--- @return number Number of in-progress tasks
function M.beads_in_progress_count()
  local stats = statusline.get_task_stats()
  return stats and stats.in_progress or 0
end

--- Get closed task count
--- @return number Number of closed tasks
function M.beads_closed_count()
  local stats = statusline.get_task_stats()
  return stats and stats.closed or 0
end

--- Get sync status text
--- @return string Sync status indicator
function M.beads_sync_status()
  local sync = require("beads.sync")
  if sync.is_syncing() then
    return "⟳ syncing"
  end

  local since_sync = sync.time_since_last_sync()
  if since_sync == -1 then
    return "⊘ not synced"
  elseif since_sync < 5 then
    return "✓ synced"
  else
    return "⟳ syncing"
  end
end

--- Get last sync time formatted
--- @return string Last sync time or empty if never synced
function M.beads_last_sync()
  local sync = require("beads.sync")
  local since = sync.time_since_last_sync()

  if since == -1 then
    return "never"
  elseif since < 60 then
    return "now"
  elseif since < 3600 then
    return math.floor(since / 60) .. "m ago"
  elseif since < 86400 then
    return math.floor(since / 3600) .. "h ago"
  else
    return math.floor(since / 86400) .. "d ago"
  end
end

--- Get formatted task summary for statusline
--- @return string Formatted summary like "5 tasks (3 open, 1 in progress)"
function M.beads_summary()
  local stats = statusline.get_task_stats()

  if not stats or stats.total == 0 then
    return ""
  end

  local parts = {
    tostring(stats.total) .. " tasks"
  }

  if stats.open > 0 then
    table.insert(parts, stats.open .. " open")
  end

  if stats.in_progress > 0 then
    table.insert(parts, stats.in_progress .. " progress")
  end

  if stats.closed > 0 and stats.closed < 5 then
    table.insert(parts, stats.closed .. " done")
  end

  return table.concat(parts, ", ")
end

--- Get priority status (P1 count or indicator)
--- @return string Priority indicator or P1 count
function M.beads_priority_status()
  local info = statusline.get_priority_info()
  return info
end

--- Setup statusline integration
--- @param opts table Configuration options
function M.setup(opts)
  opts = opts or {}

  -- Store configuration for use by other modules
  _G._beads_statusline_config = opts

  -- Register global functions for statusline
  _G.beads_task_count = M.beads_task_count
  _G.beads_open_count = M.beads_open_count
  _G.beads_in_progress_count = M.beads_in_progress_count
  _G.beads_closed_count = M.beads_closed_count
  _G.beads_sync_status = M.beads_sync_status
  _G.beads_last_sync = M.beads_last_sync
  _G.beads_summary = M.beads_summary
  _G.beads_priority_status = M.beads_priority_status
end

return M
