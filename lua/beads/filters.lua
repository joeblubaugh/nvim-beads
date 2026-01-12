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

-- Filter matching logic for task filtering

local M = {}

--- Check if a task matches priority filter
--- @param task table Task object
--- @param priority_filters table List of priorities to match
--- @return boolean True if task matches or no filters set
local function matches_priority(task, priority_filters)
  if #priority_filters == 0 then
    return true
  end

  local task_priority = task.priority or "P2"
  for _, p in ipairs(priority_filters) do
    if task_priority == p then
      return true
    end
  end
  return false
end

--- Check if a task matches status filter
--- @param task table Task object
--- @param status_filters table List of statuses to match
--- @return boolean True if task matches or no filters set
local function matches_status(task, status_filters)
  if #status_filters == 0 then
    return true
  end

  local task_status = task.status or "open"
  for _, s in ipairs(status_filters) do
    if task_status == s then
      return true
    end
  end
  return false
end

--- Fuzzy match assignee name
--- @param name string Name to match against
--- @param pattern string Search pattern
--- @return boolean True if name matches pattern
local function fuzzy_match(name, pattern)
  if not name or not pattern then
    return false
  end

  name = string.lower(name)
  pattern = string.lower(pattern)

  local pattern_idx = 1
  for i = 1, #name do
    if pattern_idx <= #pattern and name:sub(i, i) == pattern:sub(pattern_idx, pattern_idx) then
      pattern_idx = pattern_idx + 1
    end
  end
  return pattern_idx > #pattern
end

--- Check if a task matches assignee filter
--- @param task table Task object
--- @param assignee_filters table List of assignee patterns to match
--- @return boolean True if task matches or no filters set
local function matches_assignee(task, assignee_filters)
  if #assignee_filters == 0 then
    return true
  end

  local task_assignee = task.assignee or ""
  for _, pattern in ipairs(assignee_filters) do
    if fuzzy_match(task_assignee, pattern) then
      return true
    end
  end
  return false
end

--- Apply filters to task list using AND logic
--- @param tasks table List of tasks
--- @param filter_state table Filter state with priority, status, assignee
--- @return table Filtered task list
function M.apply_filters(tasks, filter_state)
  if not filter_state then
    return tasks
  end

  local filtered = {}

  for _, task in ipairs(tasks) do
    -- All filters must match (AND logic)
    if matches_priority(task, filter_state.priority or {})
        and matches_status(task, filter_state.status or {})
        and matches_assignee(task, filter_state.assignee or {}) then
      table.insert(filtered, task)
    end
  end

  return filtered
end

--- Check if any filters are active
--- @param filter_state table Filter state to check
--- @return boolean True if any filter is set
function M.has_active_filters(filter_state)
  if not filter_state then
    return false
  end

  return (#(filter_state.priority or {}) > 0)
      or (#(filter_state.status or {}) > 0)
      or (#(filter_state.assignee or {}) > 0)
end

--- Get filter description string
--- @param filter_state table Filter state to describe
--- @return string Human-readable filter description
function M.get_filter_description(filter_state)
  if not M.has_active_filters(filter_state) then
    return "No filters active"
  end

  local parts = {}

  if #(filter_state.priority or {}) > 0 then
    table.insert(parts, "Priority: " .. table.concat(filter_state.priority, ", "))
  end

  if #(filter_state.status or {}) > 0 then
    table.insert(parts, "Status: " .. table.concat(filter_state.status, ", "))
  end

  if #(filter_state.assignee or {}) > 0 then
    table.insert(parts, "Assignee: " .. table.concat(filter_state.assignee, ", "))
  end

  return table.concat(parts, " | ")
end

return M
