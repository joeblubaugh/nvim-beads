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

-- Built-in fuzzy finder implementation using vim.ui.select

local M = {}

--- Format a task for display
local function format_task_entry(task)
  local status_symbol = (task.status == "closed" or task.status == "complete") and "✓" or "○"
  local priority = task.priority or "P2"
  return string.format("%s [%s] [%s] %s: %s", status_symbol, priority, task.id, task.status or "open", task.title or task.name)
end

--- Open builtin picker for tasks
--- @param tasks table List of task objects
--- @param on_select function Callback when task is selected
function M.find_task(tasks, on_select)
  local items = {}
  local task_map = {}

  for i, task in ipairs(tasks) do
    local entry = format_task_entry(task)
    table.insert(items, entry)
    task_map[entry] = task
  end

  if #items == 0 then
    vim.notify("No tasks available", vim.log.levels.INFO)
    return
  end

  vim.ui.select(items, {
    prompt = "Select Beads Task: ",
  }, function(choice)
    if choice then
      on_select(task_map[choice])
    end
  end)
end

--- Open builtin picker for status selection
--- @param task table Task object
--- @param on_select function Callback with selected status
function M.find_status(task, on_select)
  local statuses = { "open", "in_progress", "closed" }

  vim.ui.select(statuses, {
    prompt = "Select Status (current: " .. (task.status or "open") .. "): ",
  }, function(choice)
    if choice then
      on_select(choice)
    end
  end)
end

--- Open builtin picker for priority selection
--- @param task table Task object
--- @param on_select function Callback with selected priority
function M.find_priority(task, on_select)
  local priorities = { "P1", "P2", "P3" }

  vim.ui.select(priorities, {
    prompt = "Select Priority (current: " .. (task.priority or "P2") .. "): ",
  }, function(choice)
    if choice then
      on_select(choice)
    end
  end)
end

return M
